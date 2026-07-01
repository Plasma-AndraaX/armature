# Personal preferences

Each contributor has a file here named after their login (local session identifier — `$USER`, or `git config user.name` as fallback): `<login>.md`, committed to the repo.

Claude automatically loads the file matching the local login at the start of each session.

## What goes in your file

- Communication preferences (response length, language, verbosity).
- Workflow preferences (branching strategy, commit message format, whether you want co-author trailers, etc.).
- Personal shortcuts (paths, aliases, environment-specific commands).

## What does NOT go here

- A convention the whole team must follow → `CLAUDE.md` or another shared doc.
- A decision about the project → `docs/adr/` or `docs/backlog/`.
- A technical lesson → `docs/lessons-technical.md`.

## Creating your file

Copy the shape below into `docs/prefs/<your-login>.md`:

```markdown
# Prefs — <login>

## Communication
- Language: <e.g. English, French>
- Response length: <e.g. terse, detailed>

## Workflow
- Branching: <e.g. feature branches, trunk-based>
- Commit style: <e.g. Conventional Commits, no co-author trailer>

## Shortcuts
- <anything environment-specific to your machine>
```
