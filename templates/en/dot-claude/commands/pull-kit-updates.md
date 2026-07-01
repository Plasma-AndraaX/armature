---
description: Pull improvements made to claude-project-kit since this project was bootstrapped, three-way-merging against any local customization of the same kit-owned files.
argument-hint: [optional — a hint about what you expect changed in the kit]
---

# Pull kit updates

The mirror image of `/propose-kit-improvement`: that skill sends changes *from* this project *to* the kit; this one brings changes *from* the kit *into* this project. Same review-before-writing discipline — **nothing is applied to this project without explicit confirmation**.

$ARGUMENTS

## Phase 1 — Locate the baseline and the kit's current state

- Read `.claude-project-kit-version` at the project root (`sha=...`, `lang=...`). If missing, there's no baseline to diff from — tell the user and stop (don't guess).
- Resolve `KIT_ROOT`: `$CLAUDE_PROJECT_KIT_HOME` env var if set, otherwise `/mnt/c/dev/claude-project-kit`, otherwise ask.
- Compute `NEW_SHA = git -C KIT_ROOT rev-parse HEAD`. If it equals the stamped `sha`, tell the user the kit hasn't moved since bootstrap and stop — nothing to pull.
- Verify the stamped `sha` is still reachable in `KIT_ROOT`'s history (`git -C KIT_ROOT cat-file -e <sha>`). If not, say precisely why and stop rather than diffing against the wrong thing.

## Phase 2 — The same candidate set as `/propose-kit-improvement`

**This list must stay identical to the one in `propose-kit-improvement.md`'s Phase 2 — if you're editing one, edit the other.**

Candidates (kit-owned): `CLAUDE.md` (boilerplate/instructional prose and routing table structure only, never substituted values or code-analysis content), `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md`, `docs/adr/template.md`, `docs/adr/README.md` (generic skeleton only), `docs/plans/template.md`, `docs/plans/README.md` (same caveat), `docs/prefs/README.md`, every `.claude/commands/*.md`, `tools/generate-dashboard.py`, `claude.sh`, `.env.claude.example`, `.gitignore`, `tools/session-end-capture.sh` (if present), and — only within `.claude/settings.json` — the memory-block hook portion and the `SessionEnd` capture hook block (including its `message`/`auto` mode argument), never `enabledPlugins` or anything else in it.

Never considered, structurally excluded: `docs/architecture.md`, `docs/operations.md`, `docs/coding-standards.md`, `docs/lessons-technical.md`, `docs/lessons-domain.md`, anything under `docs/backlog/`, numbered files under `docs/adr/`/`docs/plans/`, `docs/prefs/<login>.md` files, `docs/changelog/_next.md` and dated entries, `docs/claude-code-tooling.md`, `.claude/settings.json`'s `enabledPlugins`/other content.

**Relevance filter**: only consider a candidate path if it's either already present in this project, or would be a legitimate *addition* — i.e. a kit-owned file that didn't exist when this project was bootstrapped (a capability added to the kit since) and is relevant to this project's actual profile. Infer profile relevance from what's actually present (e.g. if `docs/workflow.md` or any `.claude/commands/new-adr.md`-style file already exists, this project is Full-profile-equivalent for this purpose) rather than trusting a stale assumption — a project's shape can have changed since bootstrap.

## Phase 3 — Three-way resolution per candidate

For each relevant candidate path, gather three versions, all normalized (placeholders substituted with *this* project's actual name/description/stack, `FULL-ONLY`/`MINIMAL-ONLY`/`CHANGELOG-ONLY` markers resolved per this project's actual profile/changelog choice — same normalization `/propose-kit-improvement` does):
- **BASE** — `git -C KIT_ROOT show <stamped-sha>:templates/<lang>/<mapped-path>`, normalized.
- **NEW** — `git -C KIT_ROOT show <NEW_SHA>:templates/<lang>/<mapped-path>`, normalized. If the path doesn't exist at `NEW_SHA`, the kit dropped it — flag as "kit removed this file" rather than silently ignoring.
- **MINE** — the project's current actual file content, or "absent" if it was never generated (irrelevant to this project) or was deleted.

Classify:
- **MINE absent, NEW is a genuine addition** → propose adding the new file.
- **MINE absent, not relevant to this project** → skip silently.
- **MINE == NEW already** → already current, skip (note in the summary count, don't detail it).
- **MINE == BASE, NEW ≠ BASE** → clean update: no local customization exists to lose. Propose applying NEW.
- **MINE ≠ BASE, NEW == BASE** → the project customized this locally and the kit hasn't touched it since — nothing to pull here (the customization stands).
- **MINE == BASE == NEW** → nothing changed anywhere, skip.
- **MINE ≠ BASE and NEW ≠ BASE — real arbitration** (this is the case the user expects to be rare: "a priori ils ne sont pas censés changer"). Attempt a structural merge first: if the regions that changed in MINE-vs-BASE and NEW-vs-BASE don't overlap, merge both changes cleanly and propose the merged result. If they do overlap, or the non-overlap is ambiguous, don't guess — present both diffs (MINE vs BASE, NEW vs BASE) side by side and let the user choose: keep mine (skip this file), take the kit's version (lose the local customization), or review a merged draft you propose.
- **The kit removed a file this project still has** → flag it, ask whether to remove it locally too or keep it (removal is never automatic).

## Phase 4 — Present before touching anything

Summarize: how many clean updates, how many new files offered, how many already current or with nothing to pull (counted, not detailed), and — the interesting part — how many need arbitration, each shown with its full BASE/MINE/NEW context. **Write nothing until the user has reviewed and confirmed**, file by file for anything non-trivial.

If everything is a clean update or nothing needs pulling, this can be a short, fast confirmation — don't manufacture ceremony where none is needed.

## Phase 5 — Apply confirmed changes

- Write each confirmed file into the project, re-substituting *this* project's own placeholder values and resolving markers for its actual profile/changelog choice — mirror `/bootstrap-claude-env` Phase 4's generation logic, don't hand-wave it.
- For arbitration cases resolved as "keep mine," touch nothing, but note in the summary that this is now a known, deliberate divergence going forward (not a stale unreviewed diff).
- Update `.claude-project-kit-version`'s `sha=` line to `NEW_SHA` once the review is done, **regardless of whether every hunk was accepted** — a declined change becomes an intentional divergence from that point forward, not something to re-litigate on every future run. Don't bump it if the user aborts before Phase 4's review completes.
- If any "keep mine" choice looks like it might be worth upstreaming, say so and suggest running `/propose-kit-improvement` next — the two skills close the loop on each other.

## What this skill does NOT do

- It never touches anything in the hard-excluded list.
- It never applies anything without the Phase 4 review, and never removes a file from the project without an explicit yes.
- It does not attempt this if the version stamp is missing or its SHA is unreachable in `KIT_ROOT`'s history.
- It does not try to be clever about a real conflict — when in doubt whether a structural merge is safe, it asks rather than silently combining two diverging edits.
