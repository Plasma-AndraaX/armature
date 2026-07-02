# Documentation

Map of the project documentation. Each document has a distinct purpose; they don't overlap.

| Document | Purpose | Nature |
|---|---|---|
| [`architecture.md`](architecture.md) | How the system works *today* | Living — update as the system evolves |
| [`operations.md`](operations.md) | Setup, build, run, debug, deploy | Living — update as tooling evolves |
| [`lessons-technical.md`](lessons-technical.md) | Technical gotchas and patterns not derivable from code | Append-only — one entry per lesson, datestamped |
| [`coding-standards.md`](coding-standards.md) | Actual style/naming conventions in force, per language/module if heterogeneous | Living — update as conventions are adopted |
<!-- FULL-ONLY --> | [`adr/`](adr/README.md) | Architecture Decision Records — numbered, short, one decision per file | Each ADR is stable once accepted; new ADRs supersede old ones |
| [`plans/`](plans/README.md) | Detailed implementation/investigation plans, attached to ADRs | Evolve while `in-progress`, frozen with a date prefix when `implemented` or `rejected` | <!-- /FULL-ONLY -->
| [`backlog/`](backlog/README.md) | Ideas / debt / deferred items not yet mature enough for an ADR | One file per topic, or grouped by theme<!-- FULL-ONLY --> — see `workflow.md` for granularity patterns<!-- /FULL-ONLY --> |
<!-- FULL-ONLY --> | [`testing.md`](testing.md) | Testing strategy: levels, philosophy, what we don't test | Living |
| [`incidents/`](incidents/README.md) | Postmortems of real-impact incidents | One file per incident, dated |
| `lessons-domain.md` *(if a rich business domain)* | Business rules and domain invariants | Append-only |
| [`prefs/`](prefs/README.md) | Per-contributor personal preferences, committed | One file per contributor |
| [`claude-code-tooling.md`](claude-code-tooling.md) | Inventory of Claude Code plugins/skills/hooks used on this project | Living | <!-- /FULL-ONLY -->
<!-- CHANGELOG-ONLY --> | [`changelog/`](changelog/README.md) | User-facing release notes — captured as-you-go, drafted at release time | `_next.md` is a running scratch file, cleared each release | <!-- /CHANGELOG-ONLY -->

## Writing guidelines

- **Lessons**: each section header is itself the lesson in actionable form (e.g. *"Don't do X under condition Y"*, not just *"X"*). Date each section at the end.
<!-- FULL-ONLY --> - **ADRs**: use the template in [`adr/template.md`](adr/template.md). Keep them short — details go in an accompanying plan. <!-- /FULL-ONLY -->
<!-- FULL-ONLY --> - **Plans**: slugged filename while `in-progress` (can evolve). Rename with `YYYY-MM-DD-` prefix when settled (implemented or rejected) — they become archaeological records. <!-- /FULL-ONLY -->
- **Architecture/Operations**: describe the *what* and the *how*. For *why*, cross-reference `lessons-*.md`<!-- FULL-ONLY --> or a specific ADR<!-- /FULL-ONLY -->.

<!-- FULL-ONLY -->
## Cross-references

- ADRs cite related plans in their frontmatter (`related-plans`).
- Plans cite their parent ADR in their frontmatter (`related-adr`).
- `architecture.md` can cite lessons and ADRs inline when a decision shapes a mechanism.
<!-- /FULL-ONLY -->
