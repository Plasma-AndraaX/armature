# Persistence strategy

Where Claude (or any AI assistant working on this repo) must write things that need to outlive a single conversation.

<!-- FULL-ONLY --> <!-- memory-block hook paragraph — keep only if the memory-block hook was enabled at bootstrap time -->
**Claude's private auto-memory (`~/.claude/projects/<project>/memory/`) is forbidden on this project** — anything worth remembering is worth versioning, readable by other contributors, and reviewable in a PR.

A `PreToolUse` hook in `.claude/settings.json` blocks any write under the memory directory and points back here.
<!-- /FULL-ONLY -->

<!-- FULL-ONLY -->
> **See also**: [`workflow.md`](workflow.md) — this document says *where* to put things; the workflow doc says *when* (ADR ↔ plan ↔ backlog lifecycle, and where points that emerge during implementation go).
<!-- /FULL-ONLY -->

## Matrix — what goes where

| Type of information | Destination | Notes |
|---|---|---|
<!-- FULL-ONLY --> | **Formal architectural decision** (deserves a title + alternatives + consequences) | [`docs/adr/`](adr/) (numbered) + `docs/plans/` companion | follow [`docs/adr/template.md`](adr/template.md) | <!-- /FULL-ONLY -->
| **Item to handle later** (rollout, debt, refactor, deferred point) | [`docs/backlog/`](backlog/) — one file per topic | free-form, follow existing files' conventions |
| **Non-obvious technical lesson** (gotcha, tooling trap, library quirk) | [`docs/lessons-technical.md`](lessons-technical.md) | dated section |
| **Non-obvious business rule** *(if this project has `lessons-domain.md`)* | [`docs/lessons-domain.md`](lessons-domain.md) | dated section |
| **Current state of the system** (architecture, how it works today) | [`docs/architecture.md`](architecture.md) | update as reality changes |
| **Setup / build / deploy** | [`docs/operations.md`](operations.md) | |
| **New frequent question** of the "Question → Read" kind | add a row to the table in [`CLAUDE.md`](../CLAUDE.md) | keep it short — CLAUDE.md is the index, not the content |
<!-- FULL-ONLY --> | **AI tooling** (plugins, skills, hooks, slash commands used or to adopt) | [`docs/claude-code-tooling.md`](claude-code-tooling.md) | | <!-- /FULL-ONLY -->
<!-- FULL-ONLY --> | **Individual contributor preference** (prompt style, aliases, personal choices not shared by the whole team) | [`docs/prefs/<login>.md`](prefs/) | one file per contributor — committed so Claude loads it every session; other contributors see it but don't apply it | <!-- /FULL-ONLY -->

## When nothing fits

If no row matches what you want to remember, **ask the user before writing**. Don't invent a new ad hoc destination.

<!-- FULL-ONLY -->
## Individual preferences (`docs/prefs/<login>.md`)

Idea: each contributor has a file named after their login (= local session identifier, e.g. `$USER` or `git config user.name`). It holds:
- communication preferences (response length, language, verbosity)
- workflow preferences (branching strategy, commit format, no-coauthor, etc.)
- personal shortcuts (paths, aliases, environment-specific commands)

It does **not** hold:
- a convention the whole team must follow → `CLAUDE.md` or another shared doc
- a decision about the project → `docs/adr/` or `docs/backlog/`
- a technical lesson → `docs/lessons-*.md`

Claude automatically loads the file matching the local login at the start of each session.
<!-- /FULL-ONLY -->

## Why this rule

- **Visibility**: conventions and preferences are auditable in PR review, not hidden in private memory.
- **Continuity**: whatever matches a session on this machine also matches a fresh checkout on another one.
- **Onboarding**: a new contributor clones the repo, reads `CLAUDE.md`, and their prefs are already documented (or they create one).
- **Versioning**: `git log` gives the history of decisions. Private memory has no reviewable history.
