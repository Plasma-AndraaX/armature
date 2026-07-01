{
  "permissions": {
    "allow": []
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "f=$(jq -r '.tool_input.file_path // \"\"'); case \"$f\" in */.claude/projects/*/memory/*) echo \"BLOCKED: writing under ~/.claude/.../memory/ is forbidden on this project. See docs/persistence-strategy.md for where to store decisions, lessons, prefs, etc.\" >&2; exit 2;; esac"
          }
        ]
      }
    ]
  }
}
