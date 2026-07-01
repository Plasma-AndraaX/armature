# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

{{PROJECT_NAME}} — {{PROJECT_ONE_LINER}}

**Stack**: {{PRIMARY_STACK}}

## Documentation

This file is intentionally short and stable. Deep context lives under [`docs/`](docs/) — consult it **before** diving in.

| Question | Read |
|---|---|
| How does the system work today? | [`docs/architecture.md`](docs/architecture.md) |
| How do I set up / build / run / deploy? | [`docs/operations.md`](docs/operations.md) |
| Why is this non-obvious? / what trap did someone already hit? | [`docs/lessons-technical.md`](docs/lessons-technical.md) |
| What's queued for later — backlog, deferred items? | [`docs/backlog/`](docs/backlog/README.md) |
| Where do I write down a decision / preference / lesson so it survives this conversation? | [`docs/persistence-strategy.md`](docs/persistence-strategy.md) — matrix of "type of info → file". |
<!-- FULL-ONLY -->
| Why was this architectural choice made? | [`docs/adr/`](docs/adr/README.md) (numbered ADRs) |
| How was *X* actually implemented / what alternatives were weighed? | [`docs/plans/`](docs/plans/README.md) (companions to ADRs) |
| When do I open an ADR vs a backlog item? / where do points that emerge during implementation go? | [`docs/workflow.md`](docs/workflow.md) — ADR ↔ plan ↔ backlog lifecycle. |
<!-- /FULL-ONLY -->

When you solve a non-obvious problem or hit a trap that isn't in the code, append a dated section to `docs/lessons-technical.md` (or `docs/lessons-domain.md` if this project has one). <!-- FULL-ONLY -->When you make an architectural choice, write a new ADR (see [`docs/adr/template.md`](docs/adr/template.md)). <!-- /FULL-ONLY -->Anything else — see [`docs/persistence-strategy.md`](docs/persistence-strategy.md) for the full matrix<!-- FULL-ONLY -->, and [`docs/workflow.md`](docs/workflow.md) for *when*<!-- /FULL-ONLY -->.

## Searching the codebase

If a search scoped to the repo comes up empty, **broaden the pattern, never the scope**. Try a different filename guess, grep on the type/module name. Avoid filesystem-wide searches outside the project root — they're slow and anything the running build references is by construction inside this repo.

## Build & Development Commands

<!-- Fill in once operations.md is written — keep this section short, point to operations.md for detail. -->

```bash
# TODO: fill in the actual commands for {{PRIMARY_STACK}}
```

## Architecture

<!-- Short pointer to architecture.md; do not duplicate its content here. -->

See [`docs/architecture.md`](docs/architecture.md) for the current system shape.

## Code Style

<!-- Fill in once the project has settled conventions (indentation, naming, linting). -->
