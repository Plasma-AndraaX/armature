---
description: Tactical view of "what do I work on now?" — remaining items ranked by readiness (🔥 hot · 🏗️ in progress · ✅ ready · ⏳ on trigger · 💤 someday), tagged fix/feature + ADR.
disable-model-invocation: true
---

# Review backlog

Produce a **tactical view** of what's left to do: the answer to *"what do I work on now?"*, not an exhaustive inventory. Don't invent anything — aggregate from canonical sources and **re-render** without rewriting them.

> **Primary axis = readiness** ("can I act on this now?"), **not** the backlog's resting priority. The resting order (README section order) is raw material; you **re-express** it as *is this actionable*, and you **compress the long tail**.

## Project overlay

Before anything else, check whether this project provides an overlay for this command at `.claude/armature/review-backlog.md` (relative to the project root).

- **If it exists**, read it and announce: "**Surcharge projet active** (`.claude/armature/review-backlog.md`)". It holds named markdown sections that extend this command:
  - `## before` / `## after` — reserved lifecycle hooks: run `## before` now (before the process below), and `## after` at the very end.
  - a section whose name matches a `[project anchor: <id>]` marker placed in this skill — inject its content at that marker's location.
  - any section matching neither a reserved hook nor a declared anchor: ignore it.
  - Execute the `## before` section now if present.
- **If it does not exist**, proceed normally — this command behaves exactly as its base, with nothing injected.

## Canonical sources (read in this order)

1. **`docs/backlog/README.md`** — skeleton. Its sections are the **resting** prioritization; they feed the readiness classification (mapping below), they are **not** the output's section plan.
2. **`docs/plans/<slug>.md`** with frontmatter `status: in-progress` — **skip `docs/plans/template.md`**, the shipped stub, whose frontmatter legitimately reads `in-progress` (it is the right starting value when a real plan is opened from it). Without this, every bootstrapped project reports a phantom active plan on every run. — extract:
   - unchecked `[ ]` items from `## Next actions`;
   - open topics from `## Open questions` not yet resolved (not `~~…~~`);
   - `Lot N — …` entries from `## Implementation lots` missing from `## Progress` / Decision log as shipped.
   - **Silent-delivery detection**: for a Lot/Phase with no "shipped" entry in `## Progress`/`## Decision log`, check the code side via a distinctive string grep. Code present + plan silent ⇒ flag in the summary as **silent delivery to acknowledge** — do NOT list as a TODO.

**Do NOT use**: `// TODO:` / `// FIXME:` / `// XXX:` in code (noisy, non-canonical); issue trackers unless referenced from the backlog/a plan.

**Exclude**: closing/archive README sections (e.g. "Reference (closed topics)"); `docs/plans/template.md` and `docs/adr/template.md`, which are stubs, not content.

> `[project anchor: silent-delivery-detection]` — if a project overlay defines a `## silent-delivery-detection` section, use its project-specific grep(s)/paths for the silent-delivery check above (e.g. domain-event files), plus any project-specific canonical sources or exclusions it lists.

> `[project anchor: readiness-classification]` — source #1 feeds a readiness classification, but the base ships **no mapping** (the rubric names are project-specific): if a project overlay defines a `## readiness-classification` section (its README-rubric → readiness-tier table), use it to drive that classification.

## Output format

One single response. Header, then 5 sections **in this fixed order**, then a summary.

**Header** (1 line):
```
# What's left — <date> · <N> open items          🐛 fix · ✨ feature · 🛠️ tech · 🧭 doctrine
```

**Item line** (🔥 / ✅ sections):
```
- <type> **Short title** — why in 1 line · effort if known · [ADR 00XX] · `backlog/<file>.md`
```
- `<type>` = one of 4 emojis (🐛 fix · ✨ feature · 🛠️ tech/debt/tooling · 🧭 doctrine/decision), inferred from the item's nature.
- `[ADR 00XX]` only if the item references an ADR/plan. Otherwise omit the tag.

**Item line** (⏳ section, the trigger is the title):
```
- ⏳ **<trigger condition>** → <type> Item title · `backlog/<file>.md`
```

### The 5 sections

1. **🔥 Hot now** *(promoted by context — 0 to 4 items max)*. Items the **current session**, a **recent commit**, or an **imminent release** make relevant *right now*. Each **must** carry the context signal that promotes it. If none: write *"Nothing promoted by context — resting view."* and move on.
2. **🏗️ Work in progress** *(by ADR / plan)*. For each `status: in-progress` plan: under a `ADR 00XX — <topic>` heading, open `[ ]` from `## Next actions` + unshipped Lots (with their type tag). A plan with nothing open: `ADR 00XX — <topic>: nothing open`.
3. **✅ Ready to start** *(trigger satisfied or no prerequisite)*. **Selective**: high-priority + targeted actions + tech debt + bundles with nothing blocking the start. Sorted by type. **Not all N items** — only the ones actually actionable and worth proposing.
4. **⏳ On trigger** *(the trigger is the title)*. Items waiting on a signal: those with a documented Trigger field **not yet satisfied**, plus README sections like "waiting on a signal" or "doctrines to mature". Scan the conditions and **match against reality**; an item whose trigger looks close/met **moves up** to ✅ (say so in the summary).
5. **💤 Someday/maybe** *(compressed — never expanded in normal mode)*. Dormant items, holes without a trigger: **counted + pointer**, not listed. E.g. `12 dormant with no active trigger → backlog/README.md § Dormant`.

> `[project anchor: context-reprioritization]` — if a project overlay defines a `## context-reprioritization` section, apply its context-scan logic when populating **🔥 Hot now** (section 1): e.g. the current conversation, recent `git log`, release state, open questions blocking an in-progress Lot. Output-only — never modify the backlog files.

**Summary (3-5 lines)**: total open items · **natural next step** (the first item of 🔥, else 🏗️, else ✅) · context promotions/demotions with their why · *stale* signals (item checked off elsewhere but not in the README, or the reverse; silent delivery) to clean up.

### Final — project `after` hook

If a project overlay defined a `## after` section, apply its instructions as the closing step. No overlay ⇒ skip entirely.
