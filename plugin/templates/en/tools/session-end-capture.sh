#!/bin/bash
# SessionEnd hook worker — headless capture (auto mode).
# Wired from .claude/settings.json as: bash tools/session-end-capture.sh
# Not meant to be run by hand (though harmless if you do — it'll just check the
# gate and likely find nothing to do outside a real Claude Code SessionEnd call).
#
# This worker does exactly ONE thing: spawn a detached `claude -p` that captures
# lessons/changelog from the session transcript. The "uncommitted work" reminder no
# longer runs here — a SessionEnd hook runs without a controlling terminal, so its
# stdout is never shown to the user; that reminder now lives in `claude.sh`, which
# owns the TTY.
#
# Key robustness point: a SessionEnd hook that does slow work (git, grep, transcript
# I/O, `sleep`) SYNCHRONOUSLY gets cancelled when the CLI shuts down ("Hook
# cancelled"), before doing anything. So we read the payload, relaunch a DETACHED
# copy of this script (setsid), and return control immediately — all the slow work
# happens in the detached copy, reparented to init.
#
# Pattern credit: adapted from a validated personal workspace hook (recursion guard,
# transcript-wait, byte-cap, prompt-in-a-temp-file to dodge escaping issues, headless
# `claude -p`). Hardened for a generic public kit: the headless run's --allowedTools
# excludes Bash (Read/Edit/Write/Glob/Grep is enough to write lessons/changelog
# files), and it never touches git — no commit, ever.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/session-end-capture.log"

# --- Recursion guard: the headless run below sets this before it starts a session
# of its own; if its own SessionEnd hook fires, this stops it cold. ---
if [ -n "$CLAUDE_HOOK_SPAWNED" ]; then
    exit 0
fi

# --- Immediate detach: return control to the CLI in < 1s so we're never cancelled.
# We read the payload (it comes from a pipe, must be consumed now) then relaunch a
# detached copy of this script that does all the slow work. ---
if [ -z "$CLAUDE_CAPTURE_DETACHED" ]; then
    PAYLOAD=$(cat)
    printf '%s' "$PAYLOAD" | CLAUDE_CAPTURE_DETACHED=1 setsid bash "$0" >/dev/null 2>&1 &
    exit 0
fi

# ===================== from here on: detached worker =====================
PAYLOAD=$(cat)
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // ""' 2>/dev/null)
SESSION_CWD=$(echo "$PAYLOAD" | jq -r '.cwd // ""' 2>/dev/null)
SESSION_CWD="${SESSION_CWD:-$SCRIPT_DIR/..}"

echo "--- session-end-capture (auto) at $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"

if [ -z "$TRANSCRIPT" ]; then
    echo "No transcript_path in payload, exiting." >> "$LOG_FILE"
    exit 0
fi

# --- Gate: only proceed if there's plausibly something worth capturing. ---
# Heuristic, not a guarantee — same "best-effort" posture as the rest of this kit.
DIRTY=false
if git -C "$SESSION_CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    [ -n "$(git -C "$SESSION_CWD" status --porcelain 2>/dev/null)" ] && DIRTY=true
fi
WROTE_SOMETHING=false
if [ -f "$TRANSCRIPT" ] && grep -qE '"name"\s*:\s*"(Write|Edit)"' "$TRANSCRIPT" 2>/dev/null; then
    WROTE_SOMETHING=true
fi
ALREADY_CAPTURED=false
if [ -f "$TRANSCRIPT" ] && grep -qE 'capture-lessons|changelog-capture' "$TRANSCRIPT" 2>/dev/null; then
    ALREADY_CAPTURED=true
fi

if { [ "$DIRTY" = false ] && [ "$WROTE_SOMETHING" = false ]; } || [ "$ALREADY_CAPTURED" = true ]; then
    echo "Gate not met (dirty=$DIRTY wrote=$WROTE_SOMETHING already_captured=$ALREADY_CAPTURED) — nothing to do." >> "$LOG_FILE"
    exit 0
fi

echo "Gate met (dirty=$DIRTY wrote=$WROTE_SOMETHING) — launching headless capture." >> "$LOG_FILE"

# Wait briefly in case the transcript hasn't hit disk yet.
if [ ! -f "$TRANSCRIPT" ]; then
    for _ in 1 2 3; do
        sleep 1
        [ -f "$TRANSCRIPT" ] && break
    done
fi
if [ ! -f "$TRANSCRIPT" ]; then
    echo "Transcript never appeared on disk, exiting." >> "$LOG_FILE"
    exit 0
fi

MAX_BYTES=4194304  # cap to the last 4MB — cost/context control, not a hard requirement

# Prompt goes in its own temp file to avoid inlining arbitrary prompt text into a
# shell command — sidesteps escaping entirely.
PROMPT_FILE=$(mktemp /tmp/claude-session-capture-prompt-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
You are running non-interactively, right after a Claude Code session ended in this
project. You've been piped the tail of that session's transcript on stdin — Claude
Code's internal JSONL transcript format (one JSON object per line, may vary between
versions; parse it defensively for user/assistant messages and tool use, don't assume
a fixed schema).

Your job: apply the EXACT same relevance filters as the `armature` plugin's
`/armature:capture-lessons` skill and, if this project uses a changelog,
`/armature:changelog-capture` — follow their criteria precisely, don't improvise
different ones. Then write any qualifying entries directly to the files they specify
(typically `docs/lessons-technical.md`, `docs/lessons-domain.md` if present,
`docs/changelog/_next.md` if present).

Hard rules:
- Do not run any git command. Do not commit. The user reviews and commits at their
  next session — that review step is not optional, it's just moved later.
- Most sessions produce nothing worth capturing. If that's the case here, do nothing
  and say so — don't manufacture a lesson to justify having run.
- Print a short summary at the end of what you captured (or "nothing worth capturing
  this pass") — this is logged for the user to read later.
PROMPT_EOF

# We're already detached (setsid at the top): no need for a nested runner, we run
# claude -p directly. The recursion guard keeps its own SessionEnd from re-launching
# another capture.
export CLAUDE_HOOK_SPAWNED=1
cd "$SESSION_CWD" || exit 0
tail -c "$MAX_BYTES" "$TRANSCRIPT" | claude -p "$(cat "$PROMPT_FILE")" \
    --allowedTools "Read Edit Write Glob Grep" \
    --permission-mode acceptEdits \
    >> "$LOG_FILE" 2>&1
echo "claude -p finished with code: $?" >> "$LOG_FILE"
echo "--- end session-end-capture (auto) ---" >> "$LOG_FILE"
rm -f "$PROMPT_FILE"

exit 0
