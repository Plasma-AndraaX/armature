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

exec claude "$@"
