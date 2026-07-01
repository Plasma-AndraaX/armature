---
description: Diff this project's kit-derived files against the claude-project-kit version that generated it, and propose a filtered, human-reviewed patch back to the kit.
argument-hint: [optional — a hint about what you think changed, if you already know]
---

# Propose a kit improvement

This project was bootstrapped from `claude-project-kit`. Over time, some of its kit-derived files may have drifted from the original in ways that would genuinely help *every* project the kit bootstraps — a clearer skill instruction, a bug fix, a better default. This skill finds those changes, filters out anything that's specific to this project, and prepares a reviewable patch. **Nothing is committed or pushed to the kit without explicit user confirmation at the end.**

$ARGUMENTS

## Phase 1 — Locate the baseline

- Read `.claude-project-kit-version` at the project root (two lines: `sha=...`, `lang=...`). If it doesn't exist, this project predates version stamping — tell the user there's no reliable baseline to diff against and stop (don't guess).
- Resolve `KIT_ROOT`: `$CLAUDE_PROJECT_KIT_HOME` env var if set, otherwise `/mnt/c/dev/claude-project-kit`, otherwise ask the user for their kit checkout path.
- Verify the stamped SHA still exists in the kit's local history (`git -C KIT_ROOT cat-file -e <sha>`). If it doesn't (rebase, shallow clone, pruned history), tell the user precisely why and stop rather than silently diffing against something else.

## Phase 2 — The candidate set (kit-owned files only)

**Only ever consider these** — never open, diff, or quote from anything outside this list:
- `CLAUDE.md` — but **only** its boilerplate/instructional prose and the routing table's structure (row wording, which rows exist). Never its substituted values (project name, description, stack) or anything filled in from this project's own code analysis (Build commands, Architecture pointer text is fine, but not actual command output).
- `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md` (if present)
- `docs/adr/template.md`, `docs/adr/README.md` (its generic skeleton only — never any ADR row a project actually added)
- `docs/plans/template.md`, `docs/plans/README.md` (same caveat)
- `docs/prefs/README.md` (the generic mechanism explanation, never an actual contributor's file)
- Every `.claude/commands/*.md` present (including this file)
- `tools/generate-dashboard.py` (if present)
- `claude.sh`, `.env.claude.example`, `.gitignore`, `tools/session-end-capture.sh` (if present)
- `.claude/settings.json` — **only** the memory-block hook portion and the `SessionEnd` capture hook block (including its `message`/`auto` mode argument), never `enabledPlugins` or anything else in it (that's this project's own choices)

**Never consider, under any circumstance, even if it looks generic**: `docs/architecture.md`, `docs/operations.md`, `docs/coding-standards.md`, `docs/lessons-technical.md`, `docs/lessons-domain.md`, anything under `docs/backlog/`, any numbered file under `docs/adr/` or `docs/plans/` (i.e. actual ADRs/plans, not the templates), `docs/prefs/<login>.md` files, `docs/changelog/_next.md` or any dated changelog entry, `docs/claude-code-tooling.md`. These are pure project content by construction — there is no scenario where diffing them for upstreaming is correct, so they're excluded structurally rather than left to judgment.

## Phase 3 — Diff each candidate

For each candidate file that exists in this project:
1. Fetch the original template content: `git -C KIT_ROOT show <sha>:templates/<lang>/<mapped-path>` (map `.claude/` back to `dot-claude/`, add back the `.tpl` suffix for files that had one).
2. **Normalize before comparing** — the original template may contain `{{PROJECT_NAME}}`/`{{PROJECT_ONE_LINER}}`/`{{PRIMARY_STACK}}` placeholders and `FULL-ONLY`/`MINIMAL-ONLY`/`CHANGELOG-ONLY` markers that were resolved for this project's profile/language/changelog choice at bootstrap time. Resolve the *original* the same way (substitute this project's actual name/description/stack, strip markers per this project's actual profile) before diffing — otherwise every file shows spurious differences that are just profile resolution, not real changes.
3. What's left after normalization is the real diff. Expect it to be empty or tiny for most files most of the time — that's normal, not a bug.

## Phase 4 — Classify and screen

For every real diff hunk:
- **Generalizable improvement**: reads the same regardless of which project it's in — a clearer instruction, a fixed typo, a corrected edge case, a genuinely useful new example. Candidate to propose.
- **Project-specific customization**: only makes sense in the context of *this* project — mentions its actual domain, names, architecture, or a preference specific to this team. Drop it, don't even show it as a "rejected" candidate with the specific content quoted — just note in the summary that N project-specific changes were found and excluded.
- **Noise**: differs only because of placeholder/marker resolution that Phase 3 should have already normalized away, or a trivial reformatting with no semantic change. Drop it.

For anything still standing after this filter, do one more pass specifically hunting for **secrets, credentials, personal names, company-specific terms, internal hostnames/URLs, or file paths that reveal something private** — even inside an otherwise-generalizable change. Redact or drop the hunk if you find any; when in doubt, drop it rather than guess it's fine.

## Phase 5 — Present before doing anything

Show the user, grouped by file: what survived the filter, a one-line reason it's generalizable, and the literal proposed diff. Also state, briefly, how many hunks were found and excluded as project-specific (without quoting their content) and how many as noise. **Do not create a branch, commit, or touch the kit checkout until the user has explicitly reviewed and confirmed** — they can accept, reject, or edit any individual hunk.

If nothing survives the filter, say so plainly and stop — "nothing generalizable found this pass" is a normal, good outcome.

## Phase 6 — Apply, locally, only after confirmation

For each confirmed hunk:
- Edit the corresponding file under `KIT_ROOT/templates/<lang>/...` (or the language-agnostic file, e.g. `.claude/commands/bootstrap-claude-env.md` itself if that's what changed) — re-inserting `{{PLACEHOLDER}}` tokens and profile markers exactly where the original had them. **Never let one of this project's own concrete values leak into the shared template** — if the original had a placeholder there, the edit must restore the placeholder, not hardcode this project's value.
- If the same fix plausibly applies to the other language variant too and wasn't itself a translation, say so and offer to draft the equivalent edit there — per `CONTRIBUTING.md`'s own expectation that `templates/en/` and `templates/fr/` move together.
- Create a branch in `KIT_ROOT` (e.g. `propose/<short-slug>`) off its current HEAD (not off the stamped SHA — the kit has likely moved on since bootstrap) and commit the accepted changes there with a clear message.
- If `KIT_ROOT/CHANGELOG.md` exists, add one line per accepted change under its `## [Unreleased]` section (create the section if it says "(nothing yet)") — plain language, same register as the rest of that file. This is the one path that's expected to keep the kit's changelog fed without relying on the maintainer remembering to do it by hand.
- Run `python3 tools/lint-templates.py` inside `KIT_ROOT` and show the result. If it fails, fix before presenting the branch as ready, or tell the user plainly if you can't.

## Phase 7 — Push/PR is a separate, explicit ask

Never push or open a PR automatically. Ask the user whether to:
- Push the branch now (requires a configured remote and credentials already available — don't provision or fetch a secret yourself; if none is available, say so and leave the branch local), then optionally open a PR (`gh pr create` if `gh` is available and a PR host is configured), or
- Leave it as a local branch and tell them exactly what to run when they're ready.

## What this skill does NOT do

- It does not touch anything in the hard-excluded list, ever, regardless of how generic a change there might look.
- It does not push or open a PR without a separate, explicit confirmation beyond the Phase 5 review.
- It does not fabricate a "nothing worth proposing" outcome as a failure — most runs should find little or nothing, and that's fine.
- It does not attempt this if the version stamp is missing or its SHA is unreachable — no best-effort guessing against the wrong baseline.
