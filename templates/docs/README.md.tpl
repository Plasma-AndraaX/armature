# Documentation

Map of the project documentation. Each document has a distinct purpose; they don't overlap.

| Document | Purpose | Nature |
|---|---|---|
| [`architecture.md`](architecture.md) | How the system works *today* | Living — update as the system evolves |
| [`operations.md`](operations.md) | Setup, build, run, debug, deploy | Living — update as tooling evolves |
| [`lessons-technical.md`](lessons-technical.md) | Technical gotchas and patterns not derivable from code | Append-only — one entry per lesson, datestamped |
| [`adr/`](adr/README.md) | Architecture Decision Records — numbered, short, one decision per file | Each ADR is stable once accepted; new ADRs supersede old ones |
| [`plans/`](plans/README.md) | Detailed implementation/investigation plans, attached to ADRs | Evolve while `in-progress`, frozen with a date prefix when `implemented` or `rejected` |
| [`backlog/`](backlog/README.md) | Ideas / debt / deferred items not yet mature enough for an ADR | One file per topic, or grouped by theme<!-- FULL-ONLY --> — see `workflow.md` for granularity patterns<!-- /FULL-ONLY --> |
<!-- FULL-ONLY -->
| [`lessons-domain.md`](lessons-domain.md) | Business rules and domain invariants | Append-only |
| [`prefs/`](prefs/README.md) | Per-contributor personal preferences, committed | One file per contributor |
| [`claude-code-tooling.md`](claude-code-tooling.md) | Inventory of Claude Code plugins/skills/hooks used on this project | Living |
<!-- /FULL-ONLY -->

## Writing guidelines

- **Lessons**: each section header is itself the lesson in actionable form (e.g. *"Don't do X under condition Y"*, not just *"X"*). Date each section at the end.
- **ADRs**: use the template in [`adr/template.md`](adr/template.md). Keep them short — details go in an accompanying plan.
- **Plans**: slugged filename while `in-progress` (can evolve). Rename with `YYYY-MM-DD-` prefix when settled (implemented or rejected) — they become archaeological records.
- **Architecture/Operations**: describe the *what* and the *how*. For *why*, cross-reference `lessons-*.md` or a specific ADR.

## Cross-references

- ADRs cite related plans in their frontmatter (`related-plans`).
- Plans cite their parent ADR in their frontmatter (`related-adr`).
- `architecture.md` can cite lessons and ADRs inline when a decision shapes a mechanism.
