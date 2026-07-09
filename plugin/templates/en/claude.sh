#!/usr/bin/env bash
# Loads local secrets/environment variables, then launches Claude Code.
#
# Real values go in .env.claude (gitignored — never commit it). Start from
# .env.claude.example, which documents both plain values and how to resolve
# a value from a password manager's CLI instead of storing it in plaintext.
#
# Usage: ./claude.sh [any claude CLI arguments]
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/.env.claude"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
else
  echo "No .env.claude found — copy .env.claude.example and fill in your values if this project needs any. Launching claude without extra env vars." >&2
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude not found in PATH — install Claude Code (https://claude.com/claude-code) before rerunning this script." >&2
  exit 1
fi

# We deliberately don't `exec`: the wrapper must regain control when the session
# ends so it can print the reminder below. A SessionEnd hook can't (it runs with no
# controlling terminal, so its stdout is never shown); this wrapper owns the TTY.
set +e
claude "$@"
rc=$?
set -e

# End-of-session nudge: if there's uncommitted work, remind to capture before
# committing. This lives here (not in a hook) because the wrapper owns the screen.
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   && [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
  cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Uncommitted work in this project.
Before you commit, consider capturing what's worth it:
  /armature:capture-lessons  (and /armature:changelog-capture if this project uses it)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi

exit "$rc"
