# Changelog — claude-project-kit

Human-readable history of the kit itself, release by release. Bumped manually and deliberately, not on every commit — that discipline would erode fast otherwise. Loosely follows [Keep a Changelog](https://keepachangelog.com/).

This is **not** the same thing as:
- `docs/changelog/` inside a *bootstrapped* project — that's a separate, generated artifact for that project's own end users.
- `.claude-project-kit-version` — the precise machine-readable SHA + language stamp that `/propose-kit-improvement` diffs against. This file is for humans deciding whether to pull in kit updates; that one is for exact diffing.

## Versioning

[SemVer](https://semver.org/)-ish: MINOR for a new user-facing capability (a new template, a new skill, a new question in the bootstrap flow), PATCH for fixes/docs-only changes, MAJOR reserved for a breaking change to something already-bootstrapped projects depend on (e.g. renaming `.claude-project-kit-version`'s format). `/propose-kit-improvement` appends to `[Unreleased]` when it applies an accepted external contribution; bumping `VERSION` and rolling `[Unreleased]` into a dated section is still a deliberate, manual step.

## [Unreleased]

### Added
- `/pull-kit-updates`: the reverse of `/propose-kit-improvement` — three-way merges kit improvements made since a project's bootstrap into its kit-owned files (BASE = original at the stamped SHA, MINE = the project's current file, NEW = the kit's current state), asking the user to arbitrate only when both sides have genuinely diverged from the common ancestor. Generated in both profiles.
- `tools/session-end-capture.sh` + `SessionEnd` hook (Full profile, opt-in, off by default): reminds or auto-captures lessons/changelog when a session ends with uncommitted, uncaptured work. `message` mode prints a visible reminder; `auto` mode spawns a detached headless `claude -p` (recursion-guarded, `--allowedTools` restricted to `Read Edit Write Glob Grep` — no Bash) that applies the same filters as `/capture-lessons`/`/changelog-capture` and writes files, but never commits. Gated on a heuristic (dirty tree or Write/Edit tool use in the transcript, and no evidence a capture skill already ran).

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
