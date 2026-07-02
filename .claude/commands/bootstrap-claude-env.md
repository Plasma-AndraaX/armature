---
description: Bootstrap the Claude Code documentation/workflow environment (CLAUDE.md, docs/, ADR↔plan↔backlog, skills) into a target project, generic across any language/stack and available in multiple content languages (see templates/<lang>/).
argument-hint: [absolute path to target project — defaults to the current directory]
---

# Bootstrap Claude environment

You are generating a **Claude Code working environment** — documentation structure, ADR↔plan↔backlog machinery, persistence conventions, and companion skills — into a target project. This is **not** a code scaffold: you never generate application code, dependencies, or a build system. The target project can be any language/stack, including one that doesn't exist yet.

Target path argument: **$ARGUMENTS**

## Phase 0 — Resolve the target directory

- If `$ARGUMENTS` is empty, target = current working directory.
- If `$ARGUMENTS` is a relative path, reject it and ask for an absolute path (this command may run from a different cwd than the target).
- If the target directory doesn't exist, create it (`mkdir -p`).
- If `<target>/CLAUDE.md` already exists, stop and ask the user how to proceed: **overwrite**, **merge**, or **abort**. Never silently overwrite existing project docs. Note on `merge`: there's nothing to diff yet at this point — Phase 0 only captures *which* of the three paths to take. Run Phases 1-4 as normal to produce the candidate content, then, right before Phase 5 commits, show a diff of what would actually change per file and apply only what the user confirms (see Phase 5).

## Phase 1 — Locate this kit's templates and pick a language

Resolve `KIT_ROOT` in this order, stop at the first hit:
1. `$CLAUDE_PROJECT_KIT_HOME` env var, if set and `$CLAUDE_PROJECT_KIT_HOME/templates` exists.
2. `./templates` relative to the current working directory (covers the case where you're running this from inside a `claude-project-kit` checkout).
3. `/mnt/c/dev/claude-project-kit/templates` (default known location on this machine).

If none exist, stop and ask the user for the path to their `claude-project-kit` checkout.

List `KIT_ROOT`'s immediate subdirectories — each one is a language variant (e.g. `en`, `fr`). Ask the user which one to use via `AskUserQuestion`, defaulting the suggested option to the language they're currently conversing in if it matches an available variant. Resolve `TPL_ROOT = KIT_ROOT/<chosen-lang>`. Every path referenced as `templates/...` in the phases below means `TPL_ROOT/...` (i.e. language-relative, not `KIT_ROOT` directly).

If only one language variant exists, skip the question and use it silently.

## Phase 2 — Analyze existing code (if any)

List the target directory (excluding `.git`). If it's empty or contains only a handful of non-code files (README, LICENSE), **skip this phase** — there's nothing to detect, move to Phase 3 with all fields blank.

Otherwise, analyze with the same ambition the native `/init` command would bring to generating a `CLAUDE.md` — this is a real pass, not a shallow manifest sniff:
- Glob for manifest/config files at the root and one level down: `package.json`, `*.csproj`/`*.sln`, `pyproject.toml`/`requirements.txt`/`Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml`/`build.gradle*`, `Dockerfile`, `docker-compose*.yml`.
- Read any existing `README`/`CONTRIBUTING` for stated conventions — reuse what's already documented there rather than re-guessing it.
- Sample actual source files (not just manifests) across each detected top-level module to ground: language/framework, **code style actually in use** (indentation, quote/naming conventions, linter/formatter config files), test setup, and what each top-level directory is really for.
- Declared scripts and CI config (`package.json` → `scripts`, `Makefile`/`Taskfile` targets, `.github/workflows/` or similar) for build/test/run/lint commands.
- Grep for `TODO`/`FIXME`/`XXX` comments across source files. If there's a non-trivial number, count them and keep a few representative samples for Phase 3 — don't triage or import them yet.
- **Check for style heterogeneity/conflict rather than picking one convention silently**: if the codebase spans multiple languages/modules, expect (don't assume away) that conventions differ between them — capture each separately. Within a single language/module, compare what a linter/formatter config *declares* against what a meaningful share of the actual sampled files *do* — a real, material conflict (not one stray file) is worth flagging for Phase 3; a config with near-universal compliance isn't.
- Scale the exploration to size: for anything beyond a handful of files, don't read the codebase yourself file-by-file — launch `Explore` agents **in parallel**, one per top-level module/directory, each asked for a structured report (module purpose, key files, conventions observed, build/test hooks).

Keep everything as draft answers for Phase 3 — present for confirmation, never commit silently. This is still a **best-effort starting point**, not a substitute for the user's own judgment on a genuinely large codebase — say so explicitly when that's the case. But the bar to aim for is "as close as reasonably achievable to what a dedicated `/init` pass would produce," not a deliberately watered-down version of it.

**Plugin/MCP discovery** (Full profile only — skip entirely for Minimal; the profile itself is only decided in Phase 3, so ask that one question first if you haven't yet, then come back here before presenting the rest of Phase 3 — that way the candidates are ready to show in the same pass): once you have a stack picture (even a thin one, or none if the target is empty), find out what's *currently* credible and relevant — don't rely on a fixed list baked into this skill, which will go stale. Delegate to the `claude-code-guide` subagent (it exists specifically to reason about current Claude Code features, plugins, and MCP servers): give it the detected stack/frameworks/services (databases, error tracking, hosting, etc.) and ask which **Anthropic-verified plugins** (`claude.com/plugins`) or **well-known official vendor MCP servers** would be relevant, plus any security considerations. If that agent is unavailable, `WebFetch` the official marketplace directly as a fallback. **Never** use a generic web search or recommend a community/unofficial MCP server this way — that's exactly the kind of unvetted supply-chain risk this discovery step needs to avoid. Keep the result as a short list of candidates for Phase 3/4, each with a one-line reason tied to something actually detected (not a generic "might be useful someday").

## Phase 3 — Framing questions

Ask the user (pre-filling defaults from Phase 2 where available):

- **Project name** — default: target directory's basename.
- **One-line description** — what the project does.
- **Primary stack** — pre-filled from Phase 2 if detected, otherwise ask.
- **Team** — solo or multiple contributors (affects whether `docs/prefs/` pulls its weight).
- **Backlog location** — this repo's `docs/backlog/` (Markdown, versioned) or an external tool already in use (Jira/Trello/Notion/Linear/GitHub Issues/other)? Don't assume: a team with an existing tracker will actively resent a competing one. If external: don't generate `docs/backlog/` at all, and in Phase 4 name that tool instead in `docs/persistence-strategy.md`'s "item to handle later" row and anywhere else `docs/backlog/` would otherwise be referenced (`CLAUDE.md`, `docs/README.md`, `docs/workflow.md` if Full profile) — a few-line manual touch-up per file, not a new placeholder mechanism.
- **Existing TODOs** *(only ask if Phase 2 found a non-trivial number)* — report the count and a few samples; ask whether to triage them into backlog items now (a one-time migration pass) or leave them as inline comments. Never import them automatically or silently — code `TODO`/`FIXME` comments are deliberately excluded as a backlog source elsewhere in this kit (see `whats-left.md`'s "do NOT use" list) precisely because they're noisy and untriaged; this question is a one-time opt-in assist, not an ongoing sync.
- **Code style conflict** *(only ask if Phase 2 flagged a real declared-vs-observed conflict)* — state both sides plainly (what the config says, what the code actually does, roughly how widespread each is) and ask which is authoritative going forward: the declared convention (config wins, treat the rest as drift to fix), the observed convention (the config is stale, update it to match reality), or the user states a different rule entirely. Record the answer, dated, in `docs/coding-standards.md`'s "Declared vs. observed" section. Skip this question entirely when there's no real conflict — don't manufacture one.
- **Profile** — **Full** (complete arsenal: ADR/plan/backlog/workflow/prefs/tooling-inventory/dashboard) or **Minimal** (just `CLAUDE.md`, `architecture.md`, `operations.md`, `lessons-technical.md`, `docs/backlog/README.md`, `docs/persistence-strategy.md`). Default recommendation: Full if team ≥ 2 or the user mentions wanting to track decisions long-term; Minimal for a prototype/POC. See `ADAPTING.md` in the kit for the full decision table — don't just ask blindly, give a recommendation with the why.
- **Memory-block hook** — **strongly recommend enabling it**, regardless of profile or team size. Private memory that never gets versioned is an easy way to silently lose decisions, drift from what the team actually agreed, or leak assumptions across projects with no audit trail — this gets worse, not better, over time, and is genuinely costly to discover after the fact. Say this plainly, don't present it as a neutral coin-flip. Still ask — don't force it — but the default answer you argue for is *yes*. If the user declines, that's their call, but make sure they've heard the reasoning first (see `docs/persistence-strategy.md.tpl`'s intro for the fuller argument). This answer gates the `MEMORYHOOK-ONLY` block in `persistence-strategy.md` (the memory-ban paragraph renders only if the hook is enabled) as well as the hook in `.claude/settings.json`, and is recorded as `memoryhook=yes|no` in the version stamp.
- **Changelog module** *(Full profile only)* — does this project ship to users who'd care about a "what changed" note (a product, an app, a public library)? If so, offer the `docs/changelog/` module (`/changelog-capture` + `/changelog-draft`, see `docs/changelog/README.md.tpl`). Skip the question entirely for Minimal profile or for projects with no real "user" in this sense (an internal script, a one-off tool) — don't generate unused ceremony.
- **Suggested plugins/MCP servers** *(Full profile only, only if the discovery step above found candidates)* — for each candidate, explain in one line why it's relevant to *this* project (tied to what was actually detected), then ask: **enable it now** (write it into `.claude/settings.json`'s `enabledPlugins`, or hand over the MCP server's setup command if it needs one), or **just record it** in `docs/claude-code-tooling.md` as `suggested` for the user to decide later. Recording happens either way — it's not one-or-the-other, see Phase 4. If enabling requires a credential/secret you don't have, don't try to obtain or provision it yourself (see Phase 5's Forgejo handling for why) — give the exact setup command and let the user run it themselves.
- **Session-end capture** *(Full profile only)* — when a session ends with uncommitted work and neither `/capture-lessons` nor `/changelog-capture` ran, should this project: do nothing (**off**), print a visible reminder pointing at `claude.sh --continue` (**message**), or spawn a detached headless `claude -p` that performs the capture itself, writing files but never committing (**auto**)? Recommend **message** as the default — it costs nothing when there's nothing to capture, and keeps a human in the loop before anything gets written. Mention **auto** as a real option for a user who wants it and accepts the tradeoff (background token cost, no live review before the write — though the change still isn't committed, so it's reviewed at the next session, just later). Don't ask this at all if the project has no `/capture-lessons` (i.e. never ask on Minimal — this question shouldn't come up there in the first place).

Use `AskUserQuestion` for these — they're genuine choices, not things to assume.

## Phase 4 — Generate

For every file under `TPL_ROOT` (the language variant chosen in Phase 1), apply this mapping to the target:
- `templates/CLAUDE.md.tpl` → `<target>/CLAUDE.md`
- `templates/docs/**/*.tpl` → `<target>/docs/**/*` (strip `.tpl`)
- `templates/docs/adr/template.md`, `templates/docs/plans/template.md`, `templates/docs/incidents/template.md` → copied verbatim (no placeholders, no `.tpl` suffix — already generic)
- `templates/dot-claude/**` → `<target>/.claude/**` (the kit stores it as `dot-claude` precisely so it isn't mistaken for the kit repo's *own* `.claude/` config)
- `templates/tools/generate-dashboard.py.tpl` → `<target>/tools/generate-dashboard.py`
- `templates/claude.sh` → `<target>/claude.sh`, then `chmod +x` it
- `templates/.env.claude.example` → `<target>/.env.claude.example` (no placeholders — copied verbatim)
- `templates/.gitignore` → `<target>/.gitignore`: if the target already has one, **append** the `.env.claude`/OS-cruft entries (checking they're not already present) rather than overwriting an existing file. Also check the resulting `.gitignore` — old and new combined — for any *broader* pattern (e.g. a pre-existing `.env.*` rule) that would silently swallow `.env.claude.example` or `claude.sh`, files this skill wants tracked, not ignored. If one exists, stage those specific files with `git add -f` in Phase 5 rather than relying on a plain `git add -A` that would silently skip them.
- If session-end capture ≠ off: `templates/tools/session-end-capture.sh` → `<target>/tools/session-end-capture.sh`, then `chmod +x` it. Also append `tools/session-end-capture.log` to `<target>/.gitignore` (noisy debug log, never worth committing).

**Placeholder substitution** — replace in every `.tpl` file:
- `{{PROJECT_NAME}}` → the confirmed project name
- `{{PROJECT_ONE_LINER}}` → the confirmed one-liner
- `{{PRIMARY_STACK}}` → the confirmed stack

**Profile-conditional blocks** — templates mark conditional content with `<!-- FULL-ONLY -->` ... `<!-- /FULL-ONLY -->`, `<!-- MINIMAL-ONLY -->` ... `<!-- /MINIMAL-ONLY -->`, `<!-- CHANGELOG-ONLY -->` ... `<!-- /CHANGELOG-ONLY -->`, and `<!-- MEMORYHOOK-ONLY -->` ... `<!-- /MEMORYHOOK-ONLY -->` markers (sometimes inline within a paragraph, sometimes wrapping whole sections/table rows — always on the same line as the row/text they gate, never a standalone marker line, to avoid leaving a blank line that breaks a Markdown table). When a block's condition holds (its profile is active / the changelog module was opted into / the memory-block hook was opted into): remove just the marker comments **and any single space directly adjacent** — a marker opening a table row (`<!-- FULL-ONLY --> | cell |`) takes the space after it so the row still starts with `|`; a marker closing a row (`| cell | <!-- /FULL-ONLY -->`) takes the space before it; a marker mid-prose keeps its surrounding spaces. When the condition doesn't hold: remove the markers *and* everything between them, including the trailing newline, so nothing is left blank. `CHANGELOG-ONLY` and `MEMORYHOOK-ONLY` are both independent of the Full/Minimal choice — the first is gated purely by the Phase 3 changelog question, the second purely by the Phase 3 memory-block hook question (so the memory-ban paragraph in `persistence-strategy.md` renders iff the hook was enabled, in either profile).

**Profile-driven file selection**:
- **Minimal**: generate only `CLAUDE.md`, `docs/README.md`, `docs/architecture.md`, `docs/operations.md`, `docs/lessons-technical.md`, `docs/coding-standards.md`, `docs/backlog/README.md`, `docs/persistence-strategy.md`, `.claude/commands/coding-standards.md`, `.claude/commands/propose-kit-improvement.md`, and `.claude/commands/pull-kit-updates.md`. Skip `docs/adr/`, `docs/plans/`, `docs/workflow.md`, `docs/testing.md`, `docs/incidents/`, `docs/prefs/`, `docs/claude-code-tooling.md`, `docs/lessons-domain.md`, `tools/generate-dashboard.py`, and the other `.claude/commands/` skills (`new-adr`, `capture-lessons`, `whats-left`, `dashboard`). Note `docs/coding-standards.md`, `.claude/commands/coding-standards.md`, `propose-kit-improvement.md`, and `pull-kit-updates.md` are generated in **both** profiles — the first is core like `architecture.md`/`operations.md`; the other two are useful regardless of profile since even a Minimal project has some kit-owned candidate files (`CLAUDE.md`, `docs/README.md`, `docs/persistence-strategy.md`, `claude.sh`, `.env.claude.example`, `.gitignore`).
- **Full**: generate everything except `docs/lessons-domain.md`, which you only generate if the project has a genuinely non-trivial business domain (ask if unsure — see `ADAPTING.md` § "Domaine métier riche ou pas ?"). Don't generate `docs/prefs/<login>.md` itself (only `docs/prefs/README.md` explaining the mechanism) — that's each contributor's own file to create.

**External backlog tool chosen in Phase 3**: don't generate `docs/backlog/` at all. In every generated file that references it (`CLAUDE.md`, `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md` if Full), replace the `docs/backlog/` reference with the named external tool instead — a direct text edit, not a new marker.

**Changelog module chosen in Phase 3**: generate `docs/changelog/README.md`, `docs/changelog/_next.md` (copied verbatim — no placeholders), `.claude/commands/changelog-capture.md`, `.claude/commands/changelog-draft.md`, and keep the `CHANGELOG-ONLY` cross-reference rows in `CLAUDE.md`, `docs/README.md`, `docs/persistence-strategy.md`, `docs/claude-code-tooling.md`. If declined: skip those four files, and strip every `CHANGELOG-ONLY` block from the files above like any other unmet condition.

**Enrichment from Phase 2** — if code analysis ran, don't leave `TODO` placeholders where you have real answers:
- `CLAUDE.md`'s Project Overview, Stack, and "Build & Development Commands" sections → fill with what was actually observed in the code, not generic language defaults. Leave its Code Style section as the short pointer to `docs/coding-standards.md` — don't duplicate style detail into `CLAUDE.md`.
- `docs/coding-standards.md`'s "Overview" + "Conventions" → one subsection per language/module if the codebase is heterogeneous (per Phase 2's finding), a single section if homogeneous. Fill each with what was actually observed (real indentation/quotes/naming/linter config), not assumed defaults. Delete the "Declared vs. observed" section entirely if Phase 2 found no real conflict; otherwise fill it from the Phase 3 answer, dated.
- `docs/architecture.md`'s Overview + "Major components" (one real one-liner per detected top-level module, informed by the Explore reports — not a placeholder) + "Key flows" if a request lifecycle or entry point was identifiable.
- `docs/operations.md`'s Setup/Build/Run/Test sections → fill with detected commands where confidently identified; leave `TODO` for what you couldn't determine (e.g. deploy process, which is rarely inferable from the repo alone).
- If Phase 3's TODO-triage question was answered "yes", convert the samples found into backlog items (or into a note for the external tool, if that's where backlog lives) following the kit's usual granularity rules (`docs/workflow.md` § *Backlog item granularity*, Full profile) rather than dumping them in unfiltered.

**`docs/claude-code-tooling.md` (Full profile) — the Inventory tables specifically never ship bare**: always fill "Hooks catalog" (the memory-block hook if enabled, and the session-end capture hook if configured — note its mode), "Custom skills" (already listed in the template), and "Plugins / MCP servers" (every candidate from the discovery step, tagged `adopted` or `suggested` per the user's Phase 3 answer). For anything tagged `suggested` that needs a credential to actually enable, put the exact setup command in "Recommended, not yet enabled" — never a provisioned secret. For anything tagged `adopted`, also add it to `<target>/.claude/settings.json`'s `enabledPlugins` (create the key if absent), in the form `"enabledPlugins": {"plugin-name@marketplace": true}` (this kit's own `.claude/settings.json` is a separate, unrelated file for working on the kit itself — not a reference for this shape). The other sections ("Strategy", "How to evaluate a new plugin/skill", "Security baseline", "References") stay as placeholders — they're intentionally a deliberate policy call for the team to write, not something to infer from a code scan.

**Version stamp**: write `<target>/.claude-project-kit-version` with five lines: `sha=<git -C KIT_ROOT rev-parse HEAD>`, `lang=<chosen language from Phase 1>`, `profile=full|minimal` (Phase 3's answer), `changelog=yes|no` (Phase 3's answer — `no` if the question was never asked, i.e. Minimal profile), and `memoryhook=yes|no` (Phase 3's memory-block hook answer). All five are needed later to normalize this project's kit-derived files against the exact original template tree (`KIT_ROOT` at that SHA, that language, profile, changelog, and memory-hook choice) without having to re-infer them from which files/paragraphs happen to still be present — see `docs/backlog/versioning-and-retro-propagation.md` in the kit for why. Generated in both profiles. `/propose-kit-improvement` and `/pull-kit-updates` must tolerate an older stamp missing any of `profile=`/`changelog=`/`memoryhook=` (a project bootstrapped before these fields existed) — fall back to inferring from file/hook presence in that case, exactly as before.

If `<target>/.claude/settings.json` already exists (pre-existing project with its own Claude config), do **not** overwrite it — show the relevant hook snippet(s) below and ask the user to merge them manually, or offer to merge them yourself with an explicit diff.

**Assembling `.claude/settings.json`** — it can carry up to two independent hook entries, each present only if its Phase 3 question was answered accordingly; there is no single static template file for the combined result, build it directly:
- **Memory-block hook** (`PreToolUse`) — the exact block from `templates/dot-claude/settings.json.tpl`, included only if opted in during Phase 3.
- **Session-end capture hook** (`SessionEnd`), included only if Phase 3's answer was `message` or `auto`:
  ```json
  "SessionEnd": [
    {
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/tools/session-end-capture.sh\" message" }
      ]
    }
  ]
  ```
  (replace `message` with `auto` per the Phase 3 answer — the mode is an argument to the script, not a separate file).

If neither hook is opted into, write `.claude/settings.json` with just the `permissions` block (no `hooks` key), or skip the file entirely if there's nothing else to configure.

## Phase 5 — Git

- If Phase 0's choice was `merge`: show the diff of every generated file against what existed before this pass, per file, and apply only the hunks the user confirms — before staging anything.
- If `<target>` is not already a git repo, run `git init`.
- Stage everything generated this pass and commit: `docs: bootstrap Claude environment` (a separate `docs:` commit if the repo already has history). Use `git add -f` for any file flagged in Phase 4's `.gitignore` check as silently swallowed by a pre-existing broader pattern.
- **Optional remote**: if `$FORGEJO_TOKEN` (or another git host token the user mentions) is present in the environment, offer to create a remote repository and push. Ask for **namespace** and **visibility** explicitly — do not default to any particular namespace/visibility for a project other than this kit's own origin. If no token is available, skip this sub-step and say so plainly in the summary rather than failing silently or improvising another auth method.

## Phase 6 — Summary

Show:
- The generated file tree.
- What was auto-detected in Phase 2 (so the user can spot-check/correct it) vs. what's still a blank `TODO`, including any unresolved code style heterogeneity worth a second look.
- Concrete next steps: flesh out `docs/architecture.md`, open a first ADR if there's already a pending decision, create `docs/prefs/<login>.md` (Full profile), regenerate the dashboard once there's at least one ADR (Full profile), run `/changelog-capture` after the next user-visible change (if the changelog module was included).
- Which plugins/MCP servers were enabled vs. just recorded as `suggested` in `docs/claude-code-tooling.md`, and the setup command for any that need a credential the user has to supply.
- That `./claude.sh` exists to launch Claude Code with local env vars pre-loaded, and that `.env.claude` (copied from `.env.claude.example`) is where secrets go — gitignored, never committed.
- The kit commit SHA stamped in `.claude-project-kit-version`, and that `/propose-kit-improvement` (send changes to the kit) and `/pull-kit-updates` (bring kit improvements into this project) both use it as their diff baseline.
- Whether session-end capture is configured, in which mode, and — for `auto` — that it writes but never commits, so uncommitted files may be waiting for review at the start of the next session (check `tools/session-end-capture.log`).

## What this skill does NOT do

- It does not install language dependencies, linters, or CI — this is a documentation/method scaffold, not an application scaffold.
- Phase 2's code analysis is best-effort discovery, not a substitute for the user actually writing `architecture.md` on a non-trivial codebase.
- It does not retro-propagate template improvements to already-bootstrapped projects — see `ADAPTING.md` § "Known limitation".
