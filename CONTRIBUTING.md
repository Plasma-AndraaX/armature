# Contributing

This kit is maintained by [Plasma-AndraaX](https://github.com/Plasma-AndraaX) as a personal tool, shared publicly under the MIT license (see [`LICENSE`](LICENSE)).

## Pull requests are welcome, with no merge guarantee

Opening a PR is always welcome. Whether it gets merged depends on a simple test: **is it generalizable and stack-agnostic, or specific/opinionated to your own workflow?**

- **Generalizable** (fixes a real bug, improves a template's clarity, adds a language variant, tightens the `/bootstrap` skill's logic) → good candidate for the core kit.
- **Specific/opinionated** (a profile tuned to one ecosystem, a doctrine the maintainer doesn't personally want to carry, a translation into a language the maintainer can't review) → better kept as your own fork or extension rather than pushed into the core. See [`docs/backlog/contribution-and-extension-model.md`](docs/backlog/contribution-and-extension-model.md) for the current thinking on a lighter-weight extension mechanism (not built yet).

## Which files get a `.tpl` suffix

A file under `plugin/templates/<lang>/` gets a `.tpl` suffix **iff** `/bootstrap`'s Phase 5 must do something to it at generation time — substitute a `{{PLACEHOLDER}}` and/or strip a `CHANGELOG-ONLY`/`MEMORYHOOK-ONLY` marker. Everything else is copied byte-for-byte and never gets the suffix: `claude.sh`, `.gitignore`, `.env.claude.example`, `docs/adr/template.md`, `docs/plans/template.md`, `docs/incidents/template.md`, `docs/changelog/_next.md`, `tools/session-end-capture.sh`. See Phase 5's file mapping in `plugin/skills/bootstrap/SKILL.md` for the authoritative, exhaustive list — don't restate or re-derive this rule elsewhere.

## Before opening a PR

- If it touches `plugin/templates/`, change **both** `plugin/templates/en/` and `plugin/templates/fr/`, keeping them in structural parity (same files, same `CHANGELOG-ONLY`/`MEMORYHOOK-ONLY` marker placement). Run `python3 tools/lint-templates.py` before submitting — it checks exactly this.
- If it touches `plugin/skills/bootstrap/SKILL.md`, keep the phases in sync with what the templates actually expect (file selection lists, marker semantics).
- Small, focused PRs are much easier to triage than large ones bundling several ideas.

## Reporting an issue vs. proposing a fix

Either is fine. If you're not sure whether something is a bug or a deliberate design choice, check [`README.md`](README.md) and [`ADAPTING.md`](ADAPTING.md) first — a fair amount of "why" is already written down there.
