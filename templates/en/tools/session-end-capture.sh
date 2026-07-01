#!/bin/bash
# SessionEnd hook worker — conditional reminder or headless auto-capture.
# Wired from .claude/settings.json as: bash tools/session-end-capture.sh <message|auto>
# Not meant to be run by hand (though harmless if you do — it'll just check the
# gate and likely find nothing to do outside a real Claude Code SessionEnd call).
#
# Pattern credit: adapted from a validated personal workspace hook (recursion
# guard, transcript-wait, byte-cap, mktemp runner with deferred prompt-file
# substitution to dodge escaping issues, detached headless `claude -p`).
# Hardened for a generic public kit: the headless run's --allowedTools excludes
# Bash (Read/Edit/Write/Glob/Grep is enough to write lessons/changelog files),
# and it never touches git — no commit, ever.

MODE="${1:-message}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/session-end-capture.log"

# --- Recursion guard: the headless run below sets this before it starts a
# session of its own; if its own SessionEnd hook fires, this stops it cold. ---
if [ -n "$CLAUDE_HOOK_SPAWNED" ]; then
    exit 0
fi

PAYLOAD=$(cat)
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // ""' 2>/dev/null)
SESSION_CWD=$(echo "$PAYLOAD" | jq -r '.cwd // ""' 2>/dev/null)
SESSION_CWD="${SESSION_CWD:-$SCRIPT_DIR/..}"

echo "--- session-end-capture ($MODE) at $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"

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

echo "Gate met (dirty=$DIRTY wrote=$WROTE_SOMETHING) — mode=$MODE" >> "$LOG_FILE"

# --- Mode: message — just print a visible reminder, no automation. ---
if [ "$MODE" = "message" ]; then
    cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This session has uncommitted work that doesn't look captured yet.
Run `./claude.sh --continue` to resume it, then `/capture-lessons`
and (if this project uses it) `/changelog-capture`.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 0
fi

# --- Mode: auto — spawn a detached headless Claude to do the capture itself. ---
if [ "$MODE" != "auto" ]; then
    echo "Unknown mode '$MODE', treating as message-only (no reminder printed for this exit path)." >> "$LOG_FILE"
    exit 0
fi

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

# Prompt goes in its own temp file so the runner script below can defer reading
# it to execution time (`\$(cat "$PROMPT_FILE")`) instead of trying to inline
# arbitrary prompt text into a shell command — sidesteps escaping entirely.
PROMPT_FILE=$(mktemp /tmp/claude-session-capture-prompt-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
You are running non-interactively, right after a Claude Code session ended in this
project. You've been piped the tail of that session's transcript on stdin — Claude
Code's internal JSONL transcript format (one JSON object per line, may vary between
versions; parse it defensively for user/assistant messages and tool use, don't assume
a fixed schema).

Your job: apply the EXACT same relevance filters as this project's own
`.claude/commands/capture-lessons.md` and, if it exists, `.claude/commands/changelog-capture.md`
— read those two files first and follow their criteria precisely, don't improvise
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

RUNNER=$(mktemp /tmp/claude-session-capture-runner-XXXXXX.sh)
cat > "$RUNNER" <<RUNNER_EOF
#!/bin/bash
export CLAUDE_HOOK_SPAWNED=1
cd "$SESSION_CWD" || exit 0
tail -c $MAX_BYTES "$TRANSCRIPT" | claude -p "\$(cat "$PROMPT_FILE")" \\
    --allowedTools "Read Edit Write Glob Grep" \\
    --permission-mode acceptEdits \\
    >> "$LOG_FILE" 2>&1
echo "claude -p finished with code: \$?" >> "$LOG_FILE"
echo "--- end session-end-capture (auto) ---" >> "$LOG_FILE"
rm -f "$PROMPT_FILE" "$RUNNER"
RUNNER_EOF
chmod +x "$RUNNER"

setsid bash "$RUNNER" </dev/null &>/dev/null &
echo "Headless capture launched in background (pid: $!)" >> "$LOG_FILE"

exit 0
