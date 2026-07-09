# Changelog — Armature

Human-readable history of the kit itself, release by release. Bumped manually and deliberately, not on every commit — that discipline would erode fast otherwise. Loosely follows [Keep a Changelog](https://keepachangelog.com/).

This is **not** the same thing as `docs/changelog/` inside a *bootstrapped* project — that's a separate, generated artifact for that project's own end users.

## Versioning

[SemVer](https://semver.org/)-ish: MINOR for a new user-facing capability (a new template, a new skill, a new question in the bootstrap flow), PATCH for fixes/docs-only changes, MAJOR reserved for a breaking change to something already-bootstrapped projects depend on. Bumping `VERSION` and rolling `[Unreleased]` into a dated section is a deliberate, manual step.

## [Unreleased]

### Fixed
- **The `SessionEnd` capture hook could die with "Hook cancelled" on quit.** A `SessionEnd` hook that does slow work synchronously (`git status`, `grep` over the transcript, a transcript-wait `sleep`) gets cancelled when the CLI shuts down before it finishes — most visible on slow filesystems (WSL2 `/mnt/c`). `tools/session-end-capture.sh` now reads the payload then immediately detaches all the slow work into a `setsid` copy of itself, returning control in < 1s so it's never cancelled. The `auto` path was actually the most exposed — its synchronous gate even included a `sleep` waiting for the transcript.

### Changed
- **The session-end reminder moves from the `SessionEnd` hook to `claude.sh`; auto-capture becomes the bootstrap default.** A `SessionEnd` hook runs without a controlling terminal, so its stdout is never shown to the user — the old `message` mode's reminder banner never actually reached anyone. The "uncommitted work — remember to capture" nudge now lives in `claude.sh` (the wrapper owns the TTY and prints it once the session ends) and is **unconditional**. The hook's `message` mode is removed; `session-end-capture.sh` keeps only the headless `auto` capture (which still needs the `SessionEnd` payload's `transcript_path`, so that stays a hook — just detached now). The bootstrap Phase 3 question goes from {off / message / auto} to **{off / auto}, default `auto`**. See the new lesson in `docs/lessons-technical.md`.

## [0.6.1] - 2026-07-08

Three more overlay anchors on the two richest commands, surfaced while extracting Holoon's forks into overlays — so `changelog-draft` and `review-backlog` can de-fork faithfully rather than partially.

### Added
- **Three more overlay anchors, surfaced by the Holoon de-fork exercise.** Extracting Holoon's 6 forks into overlays showed the two richest commands needed injection points the base didn't have: `changelog-draft` gains `review-additions` (inject project proposals — e.g. per-entry metadata flags — *during* the review pause, not at the end); `review-backlog` gains `readiness-classification` (the base's canonical-source-#1 referenced a "(mapping below)" it never shipped — the rubric→readiness-tier table is inherently project-specific) and `context-reprioritization` (project context-scan feeding 🔥 Hot-now). Documented in `ADAPTING.md`. The mechanism maturing from real use, exactly as the extend-first design intends.

## [0.6.0] - 2026-07-08

The **command-extension mechanism** (tier b): a consuming project can now extend any of the 6 base-mapped commands via a project overlay `.claude/armature/<cmd>.md` (reserved `before`/`after` hooks + named `[project anchor: <id>]` points), **extend-only and opt-in** — without forking, and keeping the base at the plugin. See ADR 0006 (extensibility model) + ADR 0007 (build the mechanism).

### Added
- **ADR 0006 — command-extensibility model.** Settles how a consuming project customizes a plugin command without forking the whole command or editing the base (triggered by Holoon's 6 heavily-customized local commands): a 3-tier model **with no new machinery** — cross-cutting conventions ride on the already-auto-loaded `CLAUDE.md` + `docs/prefs/<login>.md` (the key finding: tier (a) already exists — both files are auto-loaded and three skills already consult `docs/prefs`), heavy divergence is a sanctioned namespace-distinct local override, and a per-command anchor-point overlay (tier b) is deliberately deferred with a wake trigger. Reclasses the `command-extension-mechanism.md` backlog reflection as settled. `ADAPTING.md` gains a "Personnaliser une commande du plugin" section documenting the three tiers from a consumer's standpoint (the override path is now explicitly blessed). The other candidate follow-up (broaden "defer to project conventions" in `new-adr`) was evaluated and dropped — auto-loaded `CLAUDE.md`/`docs/prefs` already cover it, so it wasn't worth bloating a shared skill. Tier (b) stays gated-future.
- **ADR 0007 — decision to build the command-extension mechanism (tier b).** A read-only diagnostic of Holoon's 6 base-mapped commands overturned ADR 0006's premise that Holoon is an override case: all 6 are *extensions* of the base (5 clean + 1 hybrid `changelog-draft`, zero real replacements), so the extension need is universal, not niche. ADR 0007 (accepted) decides to build the extend-first overlay mechanism — dispatch `/armature:<nom>` → optional project overlay at named anchors, extend-only, localization out of scope — revising 0006's tier-(b) deferral. **Implemented on all 6 base-mapped commands** (`new-adr`, `capture-lessons`, `changelog-capture`, `dashboard`, `review-backlog`, `changelog-draft`): a project overlay at `.claude/armature/<cmd>.md` with reserved `before`/`after` lifecycle hooks + named `[project anchor: <id>]` injection points; **extend-only and opt-in** (no overlay ⇒ base behavior unchanged). Validated by fresh-agent dry runs on `new-adr` (4/4), `capture-lessons`, and the heavy `changelog-draft` case; documented in `ADAPTING.md`. Localization (Lot 4) stays gated-future.

## [0.5.0] - 2026-07-06

Major reshaping: Armature is renamed and turned into a **Claude Code plugin**. See ADR 0004 (plugin distribution) and ADR 0005 (post-plugin simplifications).

### Changed
- **Renamed `claude-project-kit` → `Armature`** — repo (`github.com/Plasma-AndraaX/armature`), all docs, skill descriptions, prose.
- **Armature is now a Claude Code plugin (`armature`).** The kit's commands are plugin skills invoked as `/armature:…`, installed once (`/plugin marketplace add Plasma-AndraaX/armature` then `/plugin install armature@armature`) instead of copied into every bootstrapped project. Templates are bundled in the plugin and resolved via `${CLAUDE_PLUGIN_ROOT}` — no more hard-coded `/mnt/c/dev/armature` path or `$ARMATURE_HOME` env var. Content language comes from the plugin's `${user_config.lang}` option (chosen at install). See ADR 0004.
- **Command names follow the Anthropic house style** (short, kebab-case, verb-object where natural): `/armature:bootstrap`, `/armature:new-adr`, `/armature:capture-lessons`, `/armature:document-standards`, `/armature:review-backlog`, `/armature:dashboard`, `/armature:changelog-capture`, `/armature:changelog-draft` — renamed from the longer `bootstrap-claude-env`/`coding-standards`/`whats-left`.
- **Single profile.** The Full/Minimal axis is gone: `FULL-ONLY`/`MINIMAL-ONLY` markers were flattened to always-on, the bootstrap no longer asks about profile, and `lint-templates.py` now only checks the orthogonal `CHANGELOG` × `MEMORYHOOK` combinations. See ADR 0005.

### Removed
- **`/propose-kit-improvement` and `/pull-kit-updates`.** The plugin updates via `/plugin update`; generated docs are too project-specific for a useful three-way merge. Retro-propagation is back to a manual diff (`ADAPTING.md` § "Known limitation").
- **The `.armature-version` version stamp** — its only role was the propose/pull diff baseline.

### Migration
- The two deployed projects (`voxtrail`, `Unfog`) were migrated by hand during the rebrand; they'll install the plugin and drop their copied commands at distribution time.

## [0.4.0] - 2026-07-02

### Added
- `/coding-standards` command (both profiles): proposes or refreshes `docs/coding-standards.md` from the project's stack, pulling idiomatic conventions (formatter + style guide) from a live docs source (`find-docs`/`ctx7`) when available, falling back to model knowledge (flagged) otherwise. Documentation only — never installs or configures a tool; offers a derived `.editorconfig` but doesn't impose it. Fills the new-project gap without bloating the bootstrap. See ADR 0003.
- New `MEMORYHOOK-ONLY` marker axis + `memoryhook=yes|no` version-stamp field, gated purely by the Phase 3 memory-block-hook question (independent of Full/Minimal, like `CHANGELOG-ONLY`). Wired through `lint-templates.py` (`ALL_TAGS` + memoryhook combos), `bootstrap-claude-env.md` (Phase 3/4), and `/propose-kit-improvement`/`/pull-kit-updates` (tolerant fallback: infer from the hook's presence in `.claude/settings.json` when the field is absent, so older stamps keep working).
- `lint-templates.py` hardening: (a) a dead-relative-link check — flags a link to a kit-template file not generated in the current profile; (b) a leading-space-before-table-row check; (c) a consecutive-blank-line check (2+ blank lines in a render). All three would have caught the anomalies below. The Markdown-shape checks are scoped to `.md` files (a `.py`/`.sh` render legitimately has PEP 8 double-blanks etc.). The linter now also covers every profile × changelog × memoryhook combination.

### Fixed
- `persistence-strategy.md`: the private-memory-ban paragraph was gated on `FULL-ONLY`, so it vanished in a Minimal project that had *enabled* the memory hook — leaving the doc the hook's error message points at silent on the rule. Now gated on the `MEMORYHOOK-ONLY` axis (renders iff the hook is enabled, in either profile). Found on a real `/bootstrap-claude-env` run (MapMeJDR).
- Dead relative links in generated docs: `README.md`'s `adr/`+`plans/` table rows and the ADR/Plans/Cross-references bullets are now `FULL-ONLY` (they pointed at directories a Minimal project doesn't have); `lessons-domain.md` links in `README.md` and `persistence-strategy.md` are now un-linked code spans (that file is only generated for a rich business domain). Found on the same run + surfaced by the new dead-link check.
- `strip_markers` now strips a marker symmetrically — a marker opening/closing a table row takes its adjacent space so rendered rows start with `|` instead of a stray leading space; a marker mid-prose keeps its surrounding spaces. Also removed a maintainer-only HTML comment that used to leak into the generated `persistence-strategy.md`.
- `strip_markers` no longer leaves blank lines behind: a marker alone on its line (multi-line prose blocks like `MEMORYHOOK-ONLY`) is removed as a whole line, and removing a gated block absorbs one framing blank line — so neither an active standalone marker nor a stripped block collapses into a double/triple blank line. Found re-applying the kit to MapMeJDR; guarded by the new consecutive-blank-line check. Convention note in `CLAUDE.md` clarified: standalone marker lines are fine around a prose block (only table rows require inline markers).

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
