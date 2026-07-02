# Changelog — claude-project-kit

Human-readable history of the kit itself, release by release. Bumped manually and deliberately, not on every commit — that discipline would erode fast otherwise. Loosely follows [Keep a Changelog](https://keepachangelog.com/).

This is **not** the same thing as:
- `docs/changelog/` inside a *bootstrapped* project — that's a separate, generated artifact for that project's own end users.
- `.claude-project-kit-version` — the precise machine-readable SHA + language stamp that `/propose-kit-improvement` diffs against. This file is for humans deciding whether to pull in kit updates; that one is for exact diffing.

## Versioning

[SemVer](https://semver.org/)-ish: MINOR for a new user-facing capability (a new template, a new skill, a new question in the bootstrap flow), PATCH for fixes/docs-only changes, MAJOR reserved for a breaking change to something already-bootstrapped projects depend on (e.g. renaming `.claude-project-kit-version`'s format). `/propose-kit-improvement` appends to `[Unreleased]` when it applies an accepted external contribution; bumping `VERSION` and rolling `[Unreleased]` into a dated section is still a deliberate, manual step.

## [Unreleased]

### Added
- `/coding-standards` command (both profiles): proposes or refreshes `docs/coding-standards.md` from the project's stack, pulling idiomatic conventions (formatter + style guide) from a live docs source (`find-docs`/`ctx7`) when available, falling back to model knowledge (flagged) otherwise. Documentation only — never installs or configures a tool; offers a derived `.editorconfig` but doesn't impose it. Fills the new-project gap without bloating the bootstrap. See ADR 0003.
- New `MEMORYHOOK-ONLY` marker axis + `memoryhook=yes|no` version-stamp field, gated purely by the Phase 3 memory-block-hook question (independent of Full/Minimal, like `CHANGELOG-ONLY`). Wired through `lint-templates.py` (`ALL_TAGS` + memoryhook combos), `bootstrap-claude-env.md` (Phase 3/4), and `/propose-kit-improvement`/`/pull-kit-updates` (tolerant fallback: infer from the hook's presence in `.claude/settings.json` when the field is absent, so older stamps keep working).
- `lint-templates.py` hardening: (a) a dead-relative-link check — flags a link to a kit-template file not generated in the current profile; (b) a leading-space-before-table-row check. Both would have caught the anomalies below. The linter now also covers every profile × changelog × memoryhook combination.

### Fixed
- `persistence-strategy.md`: the private-memory-ban paragraph was gated on `FULL-ONLY`, so it vanished in a Minimal project that had *enabled* the memory hook — leaving the doc the hook's error message points at silent on the rule. Now gated on the `MEMORYHOOK-ONLY` axis (renders iff the hook is enabled, in either profile). Found on a real `/bootstrap-claude-env` run (MapMeJDR).
- Dead relative links in generated docs: `README.md`'s `adr/`+`plans/` table rows and the ADR/Plans/Cross-references bullets are now `FULL-ONLY` (they pointed at directories a Minimal project doesn't have); `lessons-domain.md` links in `README.md` and `persistence-strategy.md` are now un-linked code spans (that file is only generated for a rich business domain). Found on the same run + surfaced by the new dead-link check.
- `strip_markers` now strips a marker symmetrically — a marker opening/closing a table row takes its adjacent space so rendered rows start with `|` instead of a stray leading space; a marker mid-prose keeps its surrounding spaces. Also removed a maintainer-only HTML comment that used to leak into the generated `persistence-strategy.md`.

## [0.3.0] - 2026-07-02

### Added
- `docs/testing.md` module (Full profile): a dedicated testing-strategy doc — levels, philosophy, what we deliberately don't test, definition of "tested" — distinct from `operations.md § Test` (how to run). See ADR 0001.
- `docs/incidents/` module (Full profile): one postmortem file per real-impact incident (`YYYY-MM-DD-slug.md`) with a structured template — the missing piece between "a commit" and "a lesson". Wired into `persistence-strategy`, `workflow`, `lessons-technical`, `CLAUDE.md`, `docs/README.md`, and `lint-templates.py`'s `MINIMAL_SKIP_DIRS`. See ADR 0002.
- The kit now has its own `docs/adr/` + `docs/plans/` (dogfooding its own machinery): ADR 0001 (testing strategy) and ADR 0002 (incident log), with companion plans, plus `docs/testing.md` and a first real postmortem (`docs/incidents/2026-07-01-*`).

## [0.2.0] - 2026-07-02

### Added
- `/pull-kit-updates`: the reverse of `/propose-kit-improvement` — three-way merges kit improvements made since a project's bootstrap into its kit-owned files (BASE = original at the stamped SHA, MINE = the project's current file, NEW = the kit's current state), asking the user to arbitrate only when both sides have genuinely diverged from the common ancestor. Generated in both profiles.
- `tools/session-end-capture.sh` + `SessionEnd` hook (Full profile, opt-in, off by default): reminds or auto-captures lessons/changelog when a session ends with uncommitted, uncaptured work. `message` mode prints a visible reminder; `auto` mode spawns a detached headless `claude -p` (recursion-guarded, `--allowedTools` restricted to `Read Edit Write Glob Grep` — no Bash) that applies the same filters as `/capture-lessons`/`/changelog-capture` and writes files, but never commits. Gated on a heuristic (dirty tree or Write/Edit tool use in the transcript, and no evidence a capture skill already ran).
- `.claude-project-kit-version`: two new fields, `profile=full|minimal` and `changelog=yes|no`, alongside the existing `sha=`/`lang=`. `/propose-kit-improvement` and `/pull-kit-updates` use them instead of re-inferring profile/changelog from file presence. Purely additive — both skills fall back to the old inference on a stamp from before this change.

### Fixed
- `claude.sh` (both `en`/`fr`): fail with a clear message if `claude` isn't found in `PATH`, instead of a bare shell `command not found` from `exec claude "$@"`. Surfaced via `/propose-kit-improvement` from a bootstrapped project.
- `.claude/commands/bootstrap-claude-env.md`: Phase 0's `merge` option now says explicitly that the diff review happens after Phases 1-4 generate candidate content, right before Phase 5 commits — not at Phase 0 itself, which had nothing to diff against yet.
- `.claude/commands/bootstrap-claude-env.md`: Phase 2's plugin/MCP discovery step now says explicitly it needs Phase 3's profile answer first.
- `.claude/commands/bootstrap-claude-env.md`: Phase 4's `.claude/settings.json` guidance no longer points at this kit's own `.claude/settings.json` as a shape reference for `enabledPlugins` — that file doesn't have one.
- `.claude/commands/bootstrap-claude-env.md`: Phase 4's `.gitignore` handling now checks for a pre-existing broader pattern (e.g. `.env.*`) silently shadowing `.env.claude.example`/`claude.sh`, and stages those with `git add -f` when needed.
- `templates/*/docs/claude-code-tooling.md.tpl`: removed the `/bootstrap-claude-env` row from the generated skills table — that command is never actually copied into a bootstrapped project, so the row's "if kept" condition could never be true.
- `templates/*/dot-claude/commands/propose-kit-improvement.md` + `pull-kit-updates.md`: Phase 3's `.tpl`-suffix mapping now points at `CONTRIBUTING.md`'s new documented rule instead of an unstated convention; both skills now flag the `SessionEnd` hook block's baseline as assembled dynamically (no static `.tpl` to `git show`) rather than a plain candidate path; `pull-kit-updates.md`'s arbitration case now defines "overlap" at line granularity explicitly; `propose-kit-improvement.md`'s hunk classification now says to split a unified hunk that mixes distinct changes before classifying.
- `templates/en/dot-claude/commands/pull-kit-updates.md`: fixed a leftover untranslated French phrase in the arbitration bullet.
- `CONTRIBUTING.md`: added a `Which files get a .tpl suffix` section — the exact rule was previously implicit, discoverable only by exploring `templates/` directly.

Everything above (except the `claude.sh` fix, which was itself the payload `/propose-kit-improvement` upstreamed) came out of actually running the three skills for real for the first time (2026-07-01/02) — see `docs/backlog/first-real-run-findings.md` for the full list of 10 frictions (9 fixed, 1 deliberately left to case-by-case judgment).

## [0.1.0] - 2026-07-01

Initial build.

### Added
- Bilingual template trees (`templates/en/`, `templates/fr/`), selected by `/bootstrap-claude-env` at generation time.
- Full/Minimal profile split, gated by `FULL-ONLY`/`MINIMAL-ONLY` markers across every template.
- Core docs generated into every bootstrapped project regardless of profile: `CLAUDE.md`, `docs/architecture.md`, `docs/operations.md`, `docs/lessons-technical.md`, `docs/coding-standards.md`, `docs/persistence-strategy.md`, `docs/backlog/`.
- Full-profile-only ADR/plan/backlog/workflow machinery, `docs/prefs/`, `docs/claude-code-tooling.md`, `docs/dashboard.html` generator.
- `/bootstrap-claude-env` code analysis modeled on the native `/init` command's thoroughness: manifest detection, real source sampling, code style + heterogeneity detection (declared-vs-observed conflicts surfaced, never silently resolved), TODO/FIXME surfacing, backlog-location question (this repo vs an external tracker), memory-block hook strongly recommended by default with reasoning stated plainly.
- Optional changelog module (`docs/changelog/`, `/changelog-capture`, `/changelog-draft`) — capture-then-draft pattern, deliberately without multi-locale translation — gated by a `CHANGELOG-ONLY` marker independent of the Full/Minimal profile.
- Dynamic plugin/MCP discovery via the `claude-code-guide` subagent (never a generic web search), recorded in `docs/claude-code-tooling.md` and optionally enabled in `.claude/settings.json` — recording and enabling are separate, both explicit.
- `claude.sh` launcher + `.env.claude.example` + `.gitignore`: loads local secrets (plain value, or resolved from a password manager's CLI at source time) before launching Claude Code.
- `.claude-project-kit-version` stamp (kit commit SHA + chosen template language) written into every bootstrapped project.
- `/propose-kit-improvement`: diffs a project's kit-owned files against the stamped baseline (after normalizing placeholder/marker resolution), classifies changes, structurally excludes anything that's project content by construction, screens surviving hunks for secrets/PII, and prepares a locally reviewed patch — never pushes or opens a PR without a separate, explicit confirmation.
- `LICENSE` (MIT), `CONTRIBUTING.md`, `tools/lint-templates.py` (marker balance, `en`/`fr` structural parity, full-render checks across every profile × changelog combination).
- The kit's own `docs/backlog/` — self-review findings and open design questions, dogfooding the backlog pattern (without the full ADR/plan machinery, judged premature for a solo-maintained tool at this stage).

### Known limitations
Tracked in `docs/backlog/README.md`:
- Neither `/bootstrap-claude-env` nor `/propose-kit-improvement` has been run as a real slash command in a fresh Claude Code session yet — verification so far is `tools/lint-templates.py`, a mechanical proxy for what an LLM should do reading the skill files.
- No `.ps1` equivalent of `claude.sh` for native Windows (outside WSL).
- No automated sync of already-bootstrapped projects when the kit's templates change — the version stamp gives a diff anchor, but applying changes stays a reviewed, assisted process, not automatic.
