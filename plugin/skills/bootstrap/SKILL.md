---
description: Bootstrap the Claude Code documentation/workflow environment (CLAUDE.md, docs/, ADR↔plan↔backlog, skills) into a target project, generic across any language/stack and available in multiple content languages (see templates/<lang>/).
argument-hint: [absolute path to target project — defaults to the current directory]
disable-model-invocation: true
---

# Bootstrap Claude environment

You are generating a **Claude Code working environment** — documentation structure, ADR↔plan↔backlog machinery, persistence conventions, and companion skills — into a target project. This is **not** a code scaffold: you never generate application code, dependencies, or a build system. The target project can be any language/stack, including one that doesn't exist yet.

Target path argument: **$ARGUMENTS**

## Phase 0 — Resolve the target directory

- If `$ARGUMENTS` is empty, target = current working directory.
- If `$ARGUMENTS` is a relative path, reject it and ask for an absolute path (this command may run from a different cwd than the target).
- If the target directory doesn't exist, create it (`mkdir -p`).
- If `<target>/CLAUDE.md` already exists, stop and ask the user how to proceed: **overwrite**, **merge**, or **abort**. Never silently overwrite existing project docs. Note on `merge`: there's nothing to diff yet at this point — Phase 0 only captures *which* of the three paths to take. Run Phases 1-5 as normal to produce the candidate content, then, right before Phase 6 commits, show a diff of what would actually change per file and apply only what the user confirms (see Phase 6).

## Phase 1 — Locate the bundled templates and pick a language

The templates ship **inside this plugin**. Resolve `KIT_ROOT = ${CLAUDE_PLUGIN_ROOT}/templates` — the `templates/` directory bundled next to this skill. `${CLAUDE_PLUGIN_ROOT}` is provided by Claude Code and points at the installed plugin's root; there's no external checkout to locate and no env var to set.

List `KIT_ROOT`'s immediate subdirectories — each is a language variant (e.g. `en`, `fr`). Pick the language: if `${user_config.lang}` is set (the plugin's `lang` option, chosen at install time) and names an available variant, use it; otherwise ask the user via `AskUserQuestion`, defaulting the suggested option to the language they're currently conversing in if it matches. Resolve `TPL_ROOT = KIT_ROOT/<chosen-lang>`. Every path referenced as `templates/...` in the phases below means `TPL_ROOT/...` (i.e. language-relative, not `KIT_ROOT` directly).

If only one language variant exists, skip the question and use it silently.

## Phase 2 — Analyze existing code (if any)

List the target directory (excluding `.git`). If it's empty or contains only a handful of non-code files (README, LICENSE), **skip this phase** — there's nothing to detect, move to Phase 3 with all fields blank (an empty target is precisely the case where the surrounding context is all there is).

Otherwise, analyze with the same ambition the native `/init` command would bring to generating a `CLAUDE.md` — this is a real pass, not a shallow manifest sniff:
- Glob for manifest/config files at the root and one level down: `package.json`, `*.csproj`/`*.sln`, `pyproject.toml`/`requirements.txt`/`Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml`/`build.gradle*`, `Dockerfile`, `docker-compose*.yml`.
- Read any existing `README`/`CONTRIBUTING` for stated conventions — reuse what's already documented there rather than re-guessing it.
- Sample actual source files (not just manifests) across each detected top-level module to ground: language/framework, **code style actually in use** (indentation, quote/naming conventions, linter/formatter config files), test setup, and what each top-level directory is really for.
- Declared scripts and CI config (`package.json` → `scripts`, `Makefile`/`Taskfile` targets, `.github/workflows/` or similar) for build/test/run/lint commands.
- Grep for `TODO`/`FIXME`/`XXX` comments across source files. If there's a non-trivial number, count them and keep a few representative samples for Phase 4 — don't triage or import them yet.
- **Check for style heterogeneity/conflict rather than picking one convention silently**: if the codebase spans multiple languages/modules, expect (don't assume away) that conventions differ between them — capture each separately. Within a single language/module, compare what a linter/formatter config *declares* against what a meaningful share of the actual sampled files *do* — a real, material conflict (not one stray file) is worth flagging for Phase 4; a config with near-universal compliance isn't.
- Scale the exploration to size: for anything beyond a handful of files, don't read the codebase yourself file-by-file — launch `Explore` agents **in parallel**, one per top-level module/directory, each asked for a structured report (module purpose, key files, conventions observed, build/test hooks).

Keep everything as draft answers for Phase 4 — present for confirmation, never commit silently. This is still a **best-effort starting point**, not a substitute for the user's own judgment on a genuinely large codebase — say so explicitly when that's the case. But the bar to aim for is "as close as reasonably achievable to what a dedicated `/init` pass would produce," not a deliberately watered-down version of it.

**Plugin/MCP discovery**: once you have a stack picture (even a thin one, or none if the target is empty), find out what's *currently* credible and relevant — don't rely on a fixed list baked into this skill, which will go stale. Delegate to the `claude-code-guide` subagent (it exists specifically to reason about current Claude Code features, plugins, and MCP servers): give it the detected stack/frameworks/services (databases, error tracking, hosting, etc.) and ask which **Anthropic-verified plugins** (`claude.com/plugins`) or **well-known official vendor MCP servers** would be relevant, plus any security considerations. If that agent is unavailable, `WebFetch` the official marketplace directly as a fallback. **Never** use a generic web search or recommend a community/unofficial MCP server this way — that's exactly the kind of unvetted supply-chain risk this discovery step needs to avoid. Keep the result as a short list of candidates for Phase 4/5, each with a one-line reason tied to something actually detected (not a generic "might be useful someday").

## Phase 3 — Harvest the surrounding context (skip when there's nothing to harvest)

Phase 2 mined the **code**. But most of what belongs in `docs/lessons-technical.md`, `docs/backlog/` and `docs/adr/` was never in the code: at bootstrap time it usually sits in the conversation that just happened, in a document outside the repo, or in the commit history. Without this phase those three directories ship empty with nothing but their template entry, and that material is lost the moment the session ends.

**This phase is opportunistic, not mandatory.** Check the three sources below cheaply; if none of them has anything (a fresh session that opened straight on this command, no git history, no external document), say so in one line and go to Phase 4. A bootstrap in a fresh session must stay exactly as fast as it is without this phase.

### The three sources, richest first

1. **The current conversation** — you're already in it; re-read it. This is the richest source and the only one that disappears if it isn't captured now: decisions already argued out, traps actually hit, features asked for out loud. Only mine it if the session did real work *before* the bootstrap was invoked — if the user's first message was this command, there is nothing here, and you must not invent any.
2. **Documents outside the repo** — **ask, don't assume**: a project note, decision records, a spec, an enclosing workspace's `CLAUDE.md`. Ask the user, in one `AskUserQuestion`, whether any such document should be poured in, and take **paths** (or pasted content). Read only what they name — never go hunting through the filesystem outside the target directory on your own. This is often where the whole *why* of the project already lives, alternatives-considered included: ready-made ADR material.
3. **Git history** — if the repo already has commits, read them (`git log -50 --format='%h %s%n%b'`). Messages carry decisions and traps that never made it into a doc. Skip on an empty history.

### The filter matters more than the collection

A conversation is mostly chatter, and a bootstrap that dumps it into the docs is worse than one that ships empty files. Filter hard, then route each survivor:

- **`docs/lessons-technical.md`** — same bar as `/armature:capture-lessons`, unchanged: it must cost the next person real time (> 30 min) to rediscover, stay true regardless of who's reading, be actionable, and **not** be derivable from the code. A fixed bug, a library version, a convention already visible in the code: not a lesson.
- **`docs/backlog/`** — a wanted feature or a known pain that isn't done. Follow the granularity rules in the generated `docs/workflow.md` (one file, grouped file, or PRIMARY bundle) rather than one file per sentence heard.
- **`docs/adr/`** — only for a decision that is **visibly already settled and argued**: the alternatives were actually weighed (in the conversation or in the external document) and one was chosen. Write it `status: accepted`, dated the day it was settled — not an empty `proposed` shell. A decision still pending is a *backlog* item, not an ADR; never manufacture alternatives you didn't hear. Number the ADRs in the order the decisions were settled, from `0001` up, and add their rows to `docs/adr/README.md`. Do **not** open a companion plan for a decision already implemented before the bootstrap — leave `related-plans` empty and say so in the ADR.

Two or three lessons and a handful of backlog items is a normal harvest. A dozen lessons means the filter isn't doing its job.

### Propose, never write silently

Present the shortlist grouped by destination — one line per candidate, each with the source it came from (conversation / `<document>` / commit `abc1234`) — followed by a one-line-each tail of what you filtered out and why, so the user can see the filter at work. Same contract as the TODO-triage question: the user confirms, edits, or drops, item by item. Only what's confirmed gets written, in Phase 5. If the user takes nothing, the three directories are generated from their templates exactly as before.

## Phase 4 — Framing questions

Ask the user (pre-filling defaults from Phase 2 and Phase 3 where available — an external document poured in at Phase 3 often states the project's name, one-liner and purpose better than the code does):

- **Project name** — default: target directory's basename.
- **One-line description** — what the project does.
- **Primary stack** — pre-filled from Phase 2 if detected, otherwise ask.
- **Team** — solo or multiple contributors (affects whether `docs/prefs/` pulls its weight).
- **Backlog location** — this repo's `docs/backlog/` (Markdown, versioned) or an external tool already in use (Jira/Trello/Notion/Linear/GitHub Issues/other)? Don't assume: a team with an existing tracker will actively resent a competing one. If external: don't generate `docs/backlog/` at all, and in Phase 5 name that tool instead in `docs/persistence-strategy.md`'s "item to handle later" row and anywhere else `docs/backlog/` would otherwise be referenced (`CLAUDE.md`, `docs/README.md`, `docs/workflow.md`) — a few-line manual touch-up per file, not a new placeholder mechanism.
- **Existing TODOs** *(only ask if Phase 2 found a non-trivial number)* — report the count and a few samples; ask whether to triage them into backlog items now (a one-time migration pass) or leave them as inline comments. Never import them automatically or silently — code `TODO`/`FIXME` comments are deliberately excluded as a backlog source elsewhere in this kit (see `review-backlog.md`'s "do NOT use" list) precisely because they're noisy and untriaged; this question is a one-time opt-in assist, not an ongoing sync.
- **Code style conflict** *(only ask if Phase 2 flagged a real declared-vs-observed conflict)* — state both sides plainly (what the config says, what the code actually does, roughly how widespread each is) and ask which is authoritative going forward: the declared convention (config wins, treat the rest as drift to fix), the observed convention (the config is stale, update it to match reality), or the user states a different rule entirely. Record the answer, dated, in `docs/coding-standards.md`'s "Declared vs. observed" section. Skip this question entirely when there's no real conflict — don't manufacture one.
- **Memory-block hook** — **strongly recommend enabling it**, regardless of profile or team size. Private memory that never gets versioned is an easy way to silently lose decisions, drift from what the team actually agreed, or leak assumptions across projects with no audit trail — this gets worse, not better, over time, and is genuinely costly to discover after the fact. Say this plainly, don't present it as a neutral coin-flip. Still ask — don't force it — but the default answer you argue for is *yes*. If the user declines, that's their call, but make sure they've heard the reasoning first (see `docs/persistence-strategy.md.tpl`'s intro for the fuller argument). This answer gates the `MEMORYHOOK-ONLY` block in `persistence-strategy.md` (the memory-ban paragraph renders only if the hook is enabled) as well as the hook in `.claude/settings.json`, and is recorded as `memoryhook=yes|no` in the version stamp.
- **Changelog module** — does this project ship to users who'd care about a "what changed" note (a product, an app, a public library)? If so, offer the `docs/changelog/` module (the `/armature:changelog-capture` + `/armature:changelog-draft` skills act on it, see `docs/changelog/README.md.tpl`). Skip the question entirely for projects with no real "user" in this sense (an internal script, a one-off tool) — don't generate unused ceremony.
- **Suggested plugins/MCP servers** *(only if the discovery step above found candidates)* — for each candidate, explain in one line why it's relevant to *this* project (tied to what was actually detected), then ask: **enable it now** (write it into `.claude/settings.json`'s `enabledPlugins`, or hand over the MCP server's setup command if it needs one), or **just record it** in `docs/claude-code-tooling.md` as `suggested` for the user to decide later. Recording happens either way — it's not one-or-the-other, see Phase 5. If enabling requires a credential/secret you don't have, don't try to obtain or provision it yourself (see Phase 6's Forgejo handling for why) — give the exact setup command and let the user run it themselves.
- **Session-end auto-capture** — a detached headless `claude -p`, fired by a `SessionEnd` hook, that captures qualifying lessons/changelog entries from the just-ended session's transcript (it writes files but never commits). Two choices: **auto** (enabled) or **off**. Recommend **auto** as the default. State the tradeoff plainly: a background token cost per session, and no live review before the write — but the change still isn't committed, so it's reviewed at the next session, just later. Note that *regardless* of this answer, `claude.sh` always prints a plain "uncommitted work — remember to capture" reminder when the session ends (it owns the terminal; a `SessionEnd` hook can't — its stdout is never shown). So **off** doesn't mean "no nudge at all", it means "no automated capture".

Use `AskUserQuestion` for these — they're genuine choices, not things to assume.

## Phase 5 — Generate

For every file under `TPL_ROOT` (the language variant chosen in Phase 1), apply this mapping to the target:
- `templates/CLAUDE.md.tpl` → `<target>/CLAUDE.md`
- `templates/docs/**/*.tpl` → `<target>/docs/**/*` (strip `.tpl`)
- `templates/docs/adr/template.md`, `templates/docs/plans/template.md`, `templates/docs/incidents/template.md` → copied verbatim (no placeholders, no `.tpl` suffix — already generic)
- `templates/dot-claude/settings.json.tpl` → the source block for `<target>/.claude/settings.json` (assembled below, not copied verbatim). The kit stores it as `dot-claude` so it isn't mistaken for the kit repo's own `.claude/` config. Project slash-commands are **not** copied — they ship in the `armature` plugin as `/armature:…` skills.
- `templates/tools/generate-dashboard.py.tpl` → `<target>/tools/generate-dashboard.py`
- `templates/claude.sh` → `<target>/claude.sh`, then `chmod +x` it
- `templates/.env.claude.example` → `<target>/.env.claude.example` (no placeholders — copied verbatim)
- `templates/.gitignore` → `<target>/.gitignore`: if the target already has one, **append** the `.env.claude`/OS-cruft entries (checking they're not already present) rather than overwriting an existing file. Also check the resulting `.gitignore` — old and new combined — for any *broader* pattern (e.g. a pre-existing `.env.*` rule) that would silently swallow `.env.claude.example` or `claude.sh`, files this skill wants tracked, not ignored. If one exists, stage those specific files with `git add -f` in Phase 6 rather than relying on a plain `git add -A` that would silently skip them.
- If session-end auto-capture is **auto**: `templates/tools/session-end-capture.sh` → `<target>/tools/session-end-capture.sh`, then `chmod +x` it. Also append `tools/session-end-capture.log` to `<target>/.gitignore` (noisy debug log, never worth committing). If **off**, don't copy the script at all — the `claude.sh` reminder is unconditional and needs no script.

**Placeholder substitution** — replace in every `.tpl` file:
- `{{PROJECT_NAME}}` → the confirmed project name
- `{{PROJECT_ONE_LINER}}` → the confirmed one-liner
- `{{PRIMARY_STACK}}` → the confirmed stack

**Conditional blocks** — templates mark conditional content with `<!-- CHANGELOG-ONLY -->` ... `<!-- /CHANGELOG-ONLY -->` and `<!-- MEMORYHOOK-ONLY -->` ... `<!-- /MEMORYHOOK-ONLY -->` markers (sometimes inline within a paragraph or table row, sometimes on their own line around a multi-line prose block — on a **table row** the marker must stay inline on the same line, since a standalone marker line there would leave a blank line that breaks the table). When a block's condition holds (the changelog module was opted into / the memory-block hook was opted into): remove just the marker comments **and any single space directly adjacent** — a marker opening a table row takes the space after it so the row still starts with `|`; a marker closing a row takes the space before it; a marker mid-prose keeps its surrounding spaces; a marker alone on its line is removed as a **whole line** (newline included), leaving no blank line behind. When the condition doesn't hold: remove the markers *and* everything between them, including the trailing newline. Absorb one blank line that followed the block **only if the block was itself preceded by a blank line** (a standalone prose block, whose two framing blanks would otherwise collapse into a double blank line). A gated **table row** is preceded by another table row, not a blank — absorbing the blank after it would weld the next paragraph or heading onto the table and break it. The two axes are independent: `CHANGELOG-ONLY` is gated by the Phase 4 changelog question, `MEMORYHOOK-ONLY` by the Phase 4 memory-block hook question (so the memory-ban paragraph in `persistence-strategy.md` renders iff the hook was enabled).

**File selection** — generate every file under `TPL_ROOT`, with two exceptions: `docs/lessons-domain.md` only if the project has a genuinely non-trivial business domain (ask if unsure — see `ADAPTING.md` § "Domaine métier riche ou pas ?"); and `docs/prefs/<login>.md` is never generated (only `docs/prefs/README.md` explaining the mechanism — each contributor creates their own file). Slash-commands are not generated at all — they ship in the `armature` plugin.

**External backlog tool chosen in Phase 4**: don't generate `docs/backlog/` at all. In every generated file that references it (`CLAUDE.md`, `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md`), replace the `docs/backlog/` reference with the named external tool instead — a direct text edit, not a new marker.

**Changelog module chosen in Phase 4**: generate `docs/changelog/README.md` and `docs/changelog/_next.md` (copied verbatim — no placeholders), and keep the `CHANGELOG-ONLY` cross-reference rows in `CLAUDE.md`, `docs/README.md`, `docs/persistence-strategy.md`, `docs/claude-code-tooling.md`. The `/armature:changelog-capture` + `/armature:changelog-draft` skills that act on these files ship in the plugin, not per project. If declined: skip those two files, and strip every `CHANGELOG-ONLY` block from the files above like any other unmet condition.

**Enrichment from Phase 2** — if code analysis ran, don't leave `TODO` placeholders where you have real answers:
- `CLAUDE.md`'s Project Overview, Stack, and "Build & Development Commands" sections → fill with what was actually observed in the code, not generic language defaults. Leave its Code Style section as the short pointer to `docs/coding-standards.md` — don't duplicate style detail into `CLAUDE.md`.
- `docs/coding-standards.md`'s "Overview" + "Conventions" → one subsection per language/module if the codebase is heterogeneous (per Phase 2's finding), a single section if homogeneous. Fill each with what was actually observed (real indentation/quotes/naming/linter config), not assumed defaults. Delete the "Declared vs. observed" section entirely if Phase 2 found no real conflict; otherwise fill it from the Phase 4 answer, dated.
- `docs/architecture.md`'s Overview + "Major components" (one real one-liner per detected top-level module, informed by the Explore reports — not a placeholder) + "Key flows" if a request lifecycle or entry point was identifiable.
- `docs/operations.md`'s Setup/Build/Run/Test sections → fill with detected commands where confidently identified; leave `TODO` for what you couldn't determine (e.g. deploy process, which is rarely inferable from the repo alone).
- If Phase 4's TODO-triage question was answered "yes", convert the samples found into backlog items (or into a note for the external tool, if that's where backlog lives) following the kit's usual granularity rules (`docs/workflow.md` § *Backlog item granularity*) rather than dumping them in unfiltered.

**Seeding from Phase 3** — write the items the user confirmed in Phase 3, and nothing else:
- `docs/lessons-technical.md` → one entry per confirmed lesson, newest first, in the file's own format (bold actionable title, 2-3 paragraphs, `_Captured YYYY-MM-DD._`). Delete the file's `[Template — copy this shape for a new entry]` entry once at least one real entry is in — it exists only to show the shape on an empty file.
- `docs/backlog/` → one file per confirmed item (`docs/backlog/<slug>.md`), plus its line in `docs/backlog/README.md` under the section that matches its state. Never pre-assign an ADR number in a backlog item — say "candidate for a future ADR" instead (see the generated `docs/workflow.md`).
- `docs/adr/` → one `docs/adr/NNNN-<slug>.md` per confirmed already-settled decision, from the copied `template.md`, `status: accepted` and dated the day it was settled, plus its row in `docs/adr/README.md`. No companion plan for a decision already implemented (`related-plans:` stays empty).
- If backlog lives in an external tool (Phase 4 answer), don't create `docs/backlog/` — hand the confirmed items over as a ready-to-paste list for that tool instead.

**`docs/claude-code-tooling.md` — the Inventory tables specifically never ship bare**: always fill "Hooks catalog" (the memory-block hook if enabled, and the session-end auto-capture hook if enabled), "Custom skills" (already listed in the template), and "Plugins / MCP servers" (every candidate from the discovery step, tagged `adopted` or `suggested` per the user's Phase 4 answer). For anything tagged `suggested` that needs a credential to actually enable, put the exact setup command in "Recommended, not yet enabled" — never a provisioned secret. For anything tagged `adopted`, also add it to `<target>/.claude/settings.json`'s `enabledPlugins` (create the key if absent), in the form `"enabledPlugins": {"plugin-name@marketplace": true}` (this kit's own `.claude/settings.json` is a separate, unrelated file for working on the kit itself — not a reference for this shape). The other sections ("Strategy", "How to evaluate a new plugin/skill", "Security baseline", "References") stay as placeholders — they're intentionally a deliberate policy call for the team to write, not something to infer from a code scan.

If `<target>/.claude/settings.json` already exists (pre-existing project with its own Claude config), do **not** overwrite it — show the relevant hook snippet(s) below and ask the user to merge them manually, or offer to merge them yourself with an explicit diff.

**Assembling `.claude/settings.json`** — it can carry up to two independent hook entries, each present only if its Phase 4 question was answered accordingly; there is no single static template file for the combined result, build it directly:
- **Memory-block hook** (`PreToolUse`) — the exact block from `templates/dot-claude/settings.json.tpl`, included only if opted in during Phase 4.
- **Session-end auto-capture hook** (`SessionEnd`), included only if Phase 4's answer was `auto`:
  ```json
  "SessionEnd": [
    {
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/tools/session-end-capture.sh\"" }
      ]
    }
  ]
  ```
  (no mode argument — the script only does the detached auto-capture now. The session-end *reminder* is handled unconditionally by `claude.sh`, not by a hook, because a `SessionEnd` hook runs without a controlling terminal and its stdout is never shown.)

If neither hook is opted into, write `.claude/settings.json` with just the `permissions` block (no `hooks` key), or skip the file entirely if there's nothing else to configure.

## Phase 6 — Git

- If Phase 0's choice was `merge`: show the diff of every generated file against what existed before this pass, per file, and apply only the hunks the user confirms — before staging anything.
- If `<target>` is not already a git repo, run `git init`.
- Stage everything generated this pass and commit: `docs: bootstrap Claude environment` (a separate `docs:` commit if the repo already has history). Use `git add -f` for any file flagged in Phase 5's `.gitignore` check as silently swallowed by a pre-existing broader pattern.
- **Optional remote**: if `$FORGEJO_TOKEN` (or another git host token the user mentions) is present in the environment, offer to create a remote repository and push. Ask for **namespace** and **visibility** explicitly — do not default to any particular namespace/visibility for a project other than this kit's own origin. If no token is available, skip this sub-step and say so plainly in the summary rather than failing silently or improvising another auth method.

## Phase 7 — Summary

Show:
- The generated file tree.
- What was auto-detected in Phase 2 (so the user can spot-check/correct it) vs. what's still a blank `TODO`, including any unresolved code style heterogeneity worth a second look.
- Concrete next steps: flesh out `docs/architecture.md`, open a first ADR if there's already a pending decision, create `docs/prefs/<login>.md`, regenerate the dashboard once there's at least one ADR, run `/armature:changelog-capture` after the next user-visible change (if the changelog module was included).
- What Phase 3 harvested and where it landed (lessons / backlog items / accepted ADRs, with their source), or plainly that there was nothing to harvest.
- Which plugins/MCP servers were enabled vs. just recorded as `suggested` in `docs/claude-code-tooling.md`, and the setup command for any that need a credential the user has to supply.
- That `./claude.sh` exists to launch Claude Code with local env vars pre-loaded, and that `.env.claude` (copied from `.env.claude.example`) is where secrets go — gitignored, never committed.
- Whether session-end auto-capture is enabled, and — if so — that it writes but never commits, so uncommitted files may be waiting for review at the start of the next session (check `tools/session-end-capture.log`). Either way, `./claude.sh` prints an "uncommitted work — remember to capture" reminder when the session ends.

## What this skill does NOT do

- It does not install language dependencies, linters, or CI — this is a documentation/method scaffold, not an application scaffold.
- Phase 2's code analysis is best-effort discovery, not a substitute for the user actually writing `architecture.md` on a non-trivial codebase.
- Phase 3 is a filter, not a transcript: it does not log the conversation into the docs, and it does not open a `proposed` ADR for a decision that hasn't actually been settled.
- It does not retro-propagate template improvements to already-bootstrapped projects — see `ADAPTING.md` § "Known limitation".
