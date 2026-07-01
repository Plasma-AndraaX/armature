---
description: Bootstrap the Claude Code documentation/workflow environment (CLAUDE.md, docs/, ADR↔plan↔backlog, skills) into a target project, generic across any language/stack.
argument-hint: [absolute path to target project — defaults to the current directory]
---

# Bootstrap Claude environment

You are generating a **Claude Code working environment** — documentation structure, ADR↔plan↔backlog machinery, persistence conventions, and companion skills — into a target project. This is **not** a code scaffold: you never generate application code, dependencies, or a build system. The target project can be any language/stack, including one that doesn't exist yet.

Target path argument: **$ARGUMENTS**

## Phase 0 — Resolve the target directory

- If `$ARGUMENTS` is empty, target = current working directory.
- If `$ARGUMENTS` is a relative path, reject it and ask for an absolute path (this command may run from a different cwd than the target).
- If the target directory doesn't exist, create it (`mkdir -p`).
- If `<target>/CLAUDE.md` already exists, stop and ask the user how to proceed: overwrite, merge (show a diff of what would change per-file), or abort. Never silently overwrite existing project docs.

## Phase 1 — Locate this kit's templates

Resolve `KIT_ROOT` in this order, stop at the first hit:
1. `$CLAUDE_PROJECT_KIT_HOME` env var, if set and `$CLAUDE_PROJECT_KIT_HOME/templates` exists.
2. `./templates` relative to the current working directory (covers the case where you're running this from inside a `claude-project-kit` checkout).
3. `/mnt/c/dev/claude-project-kit/templates` (default known location on this machine).

If none exist, stop and ask the user for the path to their `claude-project-kit` checkout.

## Phase 2 — Analyze existing code (if any)

List the target directory (excluding `.git`). If it's empty or contains only a handful of non-code files (README, LICENSE), **skip this phase** — there's nothing to detect, move to Phase 3 with all fields blank.

Otherwise, detect the stack:
- Glob for manifest/config files at the root and one level down: `package.json`, `*.csproj`/`*.sln`, `pyproject.toml`/`requirements.txt`/`Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml`/`build.gradle*`, `Dockerfile`, `docker-compose*.yml`.
- From what you find, infer: primary language(s), framework(s), package manager, and — if present — declared scripts (`package.json` → `scripts`, `Makefile` targets, `Taskfile`, CI config under `.github/workflows/` or similar) that look like build/test/run commands.
- Note top-level directory structure (monorepo signals like `packages/`, `apps/`; a `src/` layout; a clear frontend/backend split).
- If the codebase is large (rough heuristic: more than ~50 files or more than 3-4 distinct top-level modules), don't read everything yourself — launch 1-2 `Explore` agents in parallel, each scoped to a specific area, and ask for a structured summary (detected stack, directory roles, build/test commands) rather than a file dump.

Keep what you find as draft answers for Phase 3 — you'll present them to the user for confirmation, not commit to them silently. This is a **best-effort starting point**, not an architecture audit — say so if the codebase is complex enough that `architecture.md` will need real follow-up work beyond this pass.

## Phase 3 — Framing questions

Ask the user (pre-filling defaults from Phase 2 where available):

- **Project name** — default: target directory's basename.
- **One-line description** — what the project does.
- **Primary stack** — pre-filled from Phase 2 if detected, otherwise ask.
- **Team** — solo or multiple contributors (affects whether `docs/prefs/` pulls its weight).
- **Profile** — **Full** (complete arsenal: ADR/plan/backlog/workflow/prefs/tooling-inventory/dashboard) or **Minimal** (just `CLAUDE.md`, `architecture.md`, `operations.md`, `lessons-technical.md`, `docs/backlog/README.md`, `docs/persistence-strategy.md`). Default recommendation: Full if team ≥ 2 or the user mentions wanting to track decisions long-term; Minimal for a prototype/POC. See `ADAPTING.md` in the kit for the full decision table — don't just ask blindly, give a recommendation with the why.
- **Memory-block hook** — disable Claude's private auto-memory on this project in favor of the versioned docs (like the kit's origin project does), or leave private memory active? Explain the tradeoff briefly (see `docs/persistence-strategy.md.tpl`'s intro) rather than just asking yes/no with no context.

Use `AskUserQuestion` for these — they're genuine choices, not things to assume.

## Phase 4 — Generate

For every file under `KIT_ROOT`, apply this mapping to the target:
- `templates/CLAUDE.md.tpl` → `<target>/CLAUDE.md`
- `templates/docs/**/*.tpl` → `<target>/docs/**/*` (strip `.tpl`)
- `templates/docs/adr/template.md`, `templates/docs/plans/template.md` → copied verbatim (no placeholders, no `.tpl` suffix — already generic)
- `templates/dot-claude/**` → `<target>/.claude/**` (the kit stores it as `dot-claude` precisely so it isn't mistaken for the kit repo's *own* `.claude/` config)
- `templates/tools/generate-dashboard.py.tpl` → `<target>/tools/generate-dashboard.py`

**Placeholder substitution** — replace in every `.tpl` file:
- `{{PROJECT_NAME}}` → the confirmed project name
- `{{PROJECT_ONE_LINER}}` → the confirmed one-liner
- `{{PRIMARY_STACK}}` → the confirmed stack

**Profile-conditional blocks** — templates mark profile-specific content with `<!-- FULL-ONLY -->` ... `<!-- /FULL-ONLY -->` and, more rarely, `<!-- MINIMAL-ONLY -->` ... `<!-- /MINIMAL-ONLY -->` markers (sometimes inline within a paragraph, sometimes wrapping whole sections/table rows). On the profile the block is *for*: remove just the marker comments, keep the content. On the other profile: remove the markers *and* everything between them. (A `MINIMAL-ONLY` block only exists where the Full wording would reference something — e.g. `docs/workflow.md` — that Minimal doesn't generate, and Minimal needs different, self-contained wording instead.)

**Profile-driven file selection**:
- **Minimal**: generate only `CLAUDE.md`, `docs/README.md`, `docs/architecture.md`, `docs/operations.md`, `docs/lessons-technical.md`, `docs/backlog/README.md`, `docs/persistence-strategy.md`. Skip `docs/adr/`, `docs/plans/`, `docs/workflow.md`, `docs/prefs/`, `docs/claude-code-tooling.md`, `docs/lessons-domain.md`, `tools/generate-dashboard.py`, and the `.claude/commands/` skills (`new-adr`, `capture-lessons`, `whats-left`, `dashboard`).
- **Full**: generate everything except `docs/lessons-domain.md`, which you only generate if the project has a genuinely non-trivial business domain (ask if unsure — see `ADAPTING.md` § "Domaine métier riche ou pas ?"). Don't generate `docs/prefs/<login>.md` itself (only `docs/prefs/README.md` explaining the mechanism) — that's each contributor's own file to create.

**Enrichment from Phase 2** — if code analysis ran, don't leave `TODO` placeholders where you have real answers:
- `CLAUDE.md`'s Stack line and "Build & Development Commands" section → fill with detected commands.
- `docs/architecture.md`'s Overview + a skeleton under "Major components" (one subsection per detected top-level module, left brief — the user fills in the substance).
- `docs/operations.md`'s Setup/Build/Run/Test sections → fill with detected commands where confidently identified; leave `TODO` for what you couldn't determine (e.g. deploy process, which is rarely inferable from the repo alone).

If `<target>/.claude/settings.json` already exists (pre-existing project with its own Claude config), do **not** overwrite it — show the memory-block hook snippet from `templates/dot-claude/settings.json.tpl` and ask the user to merge it manually, or offer to merge it yourself with an explicit diff.

**Memory-block hook** — write `templates/dot-claude/settings.json.tpl` as-is if the user opted in during Phase 3; otherwise write `.claude/settings.json` without the `hooks` key (permissions block only), or skip the file entirely if there's nothing else to configure.

## Phase 5 — Git

- If `<target>` is not already a git repo, run `git init`.
- Stage everything generated this pass and commit: `docs: bootstrap Claude environment` (a separate `docs:` commit if the repo already has history).
- **Optional remote**: if `$FORGEJO_TOKEN` (or another git host token the user mentions) is present in the environment, offer to create a remote repository and push. Ask for **namespace** and **visibility** explicitly — do not default to any particular namespace/visibility for a project other than this kit's own origin. If no token is available, skip this sub-step and say so plainly in the summary rather than failing silently or improvising another auth method.

## Phase 6 — Summary

Show:
- The generated file tree.
- What was auto-detected in Phase 2 (so the user can spot-check/correct it) vs. what's still a blank `TODO`.
- Concrete next steps: flesh out `docs/architecture.md`, open a first ADR if there's already a pending decision, create `docs/prefs/<login>.md` (Full profile), regenerate the dashboard once there's at least one ADR (Full profile).

## What this skill does NOT do

- It does not install language dependencies, linters, or CI — this is a documentation/method scaffold, not an application scaffold.
- Phase 2's code analysis is best-effort discovery, not a substitute for the user actually writing `architecture.md` on a non-trivial codebase.
- It does not retro-propagate template improvements to already-bootstrapped projects — see `ADAPTING.md` § "Known limitation".
