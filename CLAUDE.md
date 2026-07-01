# CLAUDE.md

Guidance for Claude Code sessions working **on this repo** (`claude-project-kit` itself). Not to be confused with `templates/*/CLAUDE.md.tpl`, which is what gets generated **into** bootstrapped projects — different audience, don't conflate the two.

## What this repo is

A bilingual (`en`/`fr`) kit that bootstraps a Claude Code documentation/workflow environment (ADR↔plan↔backlog, `CLAUDE.md`, coding standards, optional changelog module) into any project, via the `/bootstrap-claude-env` skill. See [`README.md`](README.md) for the user-facing pitch, [`ADAPTING.md`](ADAPTING.md) for the reasoning behind every non-obvious design choice.

Current version: **0.1.0** (see [`CHANGELOG.md`](CHANGELOG.md); `git log` is ahead of the `v0.1.0` tag — several features landed since). Public at `github.com/Plasma-AndraaX/claude-project-kit`.

## Structure

- `templates/en/`, `templates/fr/` — the actual templates, kept in **structural parity** (same files, same `<!-- FULL-ONLY -->`/`<!-- MINIMAL-ONLY -->`/`<!-- CHANGELOG-ONLY -->` markers). Run `python3 tools/lint-templates.py` after touching either.
- `.claude/commands/bootstrap-claude-env.md` — the main skill, generates a project from `templates/<lang>/`.
- `templates/<lang>/dot-claude/commands/propose-kit-improvement.md` + `pull-kit-updates.md` — generated into every bootstrapped project; sync changes *to* and *from* the kit using a three-way diff anchored on `.claude-project-kit-version` (SHA + lang, stamped at bootstrap time). Both skills share a strict "kit-owned vs. project-owned" file list — if you edit one skill's Phase 2 list, edit the other's too (see `CONTRIBUTING.md`).
- `templates/<lang>/tools/session-end-capture.sh` — optional `SessionEnd` hook (message or headless-auto capture of lessons/changelog).
- `tools/lint-templates.py` — the only automated check that exists. Verifies marker balance, `en`/`fr` parity, and clean rendering across every profile × changelog combination. It does **not** verify the skills actually work when run for real — see below.
- `docs/backlog/README.md` — what's open on the kit itself (not ADR/plan machinery, deliberately — see that file's own header for why).

## Where things stand — read this first in a new session

Check [`docs/backlog/README.md`](docs/backlog/README.md) for the current state; don't trust this paragraph to stay accurate as work continues, update it here only if it goes stale. As of `0.1.0`, the single real open item: **none of `/bootstrap-claude-env`, `/propose-kit-improvement`, or `/pull-kit-updates` has ever been run as a real slash command in a live session** — every check so far is `tools/lint-templates.py`, a mechanical proxy for what an LLM *should* do reading the skill files, not proof it actually does it. That's the next priority. Everything else flagged in `docs/backlog/README.md`'s "fond de tiroir" is deliberately dormant, no active trigger.

## Working conventions

- New template content touches **both** `templates/en/` and `templates/fr/` — see `CONTRIBUTING.md`.
- Profile-conditional markers go on the **same line** as the content they gate, never a standalone marker line (a past bug: a standalone marker line leaves a blank line behind when stripped, which breaks a Markdown table mid-file).
- `/propose-kit-improvement`'s Phase 6 appends to `CHANGELOG.md`'s `[Unreleased]` section for accepted external contributions; changes made directly in a session here should get a `CHANGELOG.md` entry by hand, same discipline.
- Don't build ahead of a demonstrated need — several backlog items are deliberately deferred with a documented wake trigger rather than built speculatively (see `docs/backlog/contribution-and-extension-model.md` for the clearest example of this doctrine in action).
