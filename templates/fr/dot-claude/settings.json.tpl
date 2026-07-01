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
            "command": "f=$(jq -r '.tool_input.file_path // \"\"'); case \"$f\" in */.claude/projects/*/memory/*) echo \"BLOCKED : l'écriture sous ~/.claude/.../memory/ est interdite sur ce projet. Voir docs/persistence-strategy.md pour savoir où stocker décisions, leçons, préférences, etc.\" >&2; exit 2;; esac"
          }
        ]
      }
    ]
  }
}
