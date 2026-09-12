---
description: Tactical view of "what do I work on now?" — remaining items ranked by readiness (🔥 hot · 🏗️ in progress · ✅ ready · ⏳ on trigger · 💤 someday), plus 📥 what this conversation produced that isn't filed yet; tagged fix/feature + ADR.
disable-model-invocation: true
---

# Review backlog

Produce a **tactical view** of what's left to do: the answer to *"what do I work on now?"*, not an exhaustive inventory. Don't invent anything — aggregate from canonical sources and **re-render** without rewriting them. That ban is on *fabricating* items; it does not cover reporting what the current conversation actually produced, which is a required step (see *Conversation scan* below).

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

## Conversation scan (required step, output-only)

Both sources above are **written**. Work that so far exists only in the **current conversation** — a decision just taken, a defect just observed, a follow-up just named — is invisible to them, and is the one thing this command must not let evaporate when the session ends.

So, explicitly: re-read the current conversation and extract whatever (a) is a real, named piece of work or decision, and (b) has **no counterpart** in `docs/backlog/README.md`, an ADR, or a plan. Verify (b) before calling something unfiled — an item already recorded is not a gap, it belongs in the normal sections. This feeds **📥 From this conversation** (section 1), and nothing else: it never changes the readiness classification of a filed item.

Two guards:
- **Propose, never write.** This command stays read-only: it renders candidates, it does not touch `docs/backlog/`, an ADR, or a plan. Filing is the user's call (`/armature:new-adr` for a decision, a hand-written backlog entry otherwise).
- **Only what was said.** A fresh session with nothing behind it yields an empty section, and the section says so — it does not go looking for plausible work.

> `[project anchor: silent-delivery-detection]` — if a project overlay defines a `## silent-delivery-detection` section, use its project-specific grep(s)/paths for the silent-delivery check above (e.g. domain-event files), plus any project-specific canonical sources or exclusions it lists.

> `[project anchor: readiness-classification]` — source #1 feeds a readiness classification, but the base ships **no mapping** (the rubric names are project-specific): if a project overlay defines a `## readiness-classification` section (its README-rubric → readiness-tier table), use it to drive that classification.

## Output format

One single response. Header, then 6 sections **in this fixed order**, then a summary.

**Header** (1 line — drop the `📥 <M>` segment when M is 0):
```
# What's left — <date> · <N> open items · 📥 <M> from this session          🐛 fix · ✨ feature · 🛠️ tech · 🧭 doctrine
```

**Item line** (🔥 / ✅ sections — 📥 has its own shape, see section 1):
```
- <type> **Short title** — why in 1 line · effort if known · [ADR 00XX] · `backlog/<file>.md`
```
- `<type>` = one of 4 emojis (🐛 fix · ✨ feature · 🛠️ tech/debt/tooling · 🧭 doctrine/decision), inferred from the item's nature.
- `[ADR 00XX]` only if the item references an ADR/plan. Otherwise omit the tag.

**Item line** (⏳ section, the trigger is the title):
```
- ⏳ **<trigger condition>** → <type> Item title · `backlog/<file>.md`
```

### The 6 sections

1. **📥 From this conversation** *(unfiled — act on it or file it before the session ends)*. **First, because it is the most perishable**: what this conversation produced that no backlog file, ADR or plan records yet. Two kinds, in this order:
   - **`(mid-flight)`** — work the session started or made cheap: the context loaded right now (files read, diagnosis done, dead ends already ruled out) makes finishing it far cheaper here than from a cold session. This is the one thing that expires when the session closes.
   - the rest — the filing debt: decisions taken, defects observed, follow-ups named, with nowhere yet to live.

   One line each, phrased to be pasted as-is:
   ```
   - <type> **Short title** — 1 line of substance · `(mid-flight)` if applicable · suggested destination (`backlog/<file>.md` · new ADR · plan `<slug>` · a commit)
   ```
   Nothing unfiled: write *"Nothing to file — the conversation produced nothing the backlog doesn't already hold."* — never leave this section implicit. State the (b) check when it settles something: an item that already has a written counterpart (a `CHANGELOG` entry, a commit message) is **not** filing debt and does not belong here.
2. **🔥 Hot now** *(promoted by context — 0 to 4 items max)*. Items the **current session**, a **recent commit**, or an **imminent release** make relevant *right now*. Each **must** carry the context signal that promotes it. If none: write *"Nothing promoted by context — resting view."* and move on. This section only ever **re-ranks items that are already filed** — unfiled conversation material lives in 📥 (section 1) and is never restated here.
3. **🏗️ Work in progress** *(by ADR / plan)*. For each `status: in-progress` plan: under a `ADR 00XX — <topic>` heading, open `[ ]` from `## Next actions` + unshipped Lots (with their type tag). A plan with nothing open: `ADR 00XX — <topic>: nothing open`.
4. **✅ Ready to start** *(trigger satisfied or no prerequisite)*. **Selective**: high-priority + targeted actions + tech debt + bundles with nothing blocking the start. Sorted by type. **Not all N items** — only the ones actually actionable and worth proposing.
5. **⏳ On trigger** *(the trigger is the title)*. Items waiting on a signal: those with a documented Trigger field **not yet satisfied**, plus README sections like "waiting on a signal" or "doctrines to mature". Scan the conditions and **match against reality**; an item whose trigger looks close/met **moves up** to ✅ (say so in the summary).
6. **💤 Someday/maybe** *(compressed — never expanded in normal mode)*. Dormant items, holes without a trigger: **counted + pointer**, not listed. E.g. `12 dormant with no active trigger → backlog/README.md § Dormant`.

> `[project anchor: context-reprioritization]` — if a project overlay defines a `## context-reprioritization` section, apply its context-scan logic when populating **🔥 Hot now** (section 2): e.g. the current conversation, recent `git log`, release state, open questions blocking an in-progress Lot. Output-only — never modify the backlog files.

**Summary (3-5 lines)**: total open items · **natural next step** — the first `(mid-flight)` item of 📥, else the first item of 🔥, else 🏗️, else ✅: work the loaded context makes cheap outranks a filed item that will cost the same next week · context promotions/demotions with their why · *stale* signals (item checked off elsewhere but not in the README, or the reverse; silent delivery) to clean up · the 📥 count, called out as unfiled-and-at-risk — the non-`(mid-flight)` part is consignment debt, not work to do now.

### Final — project `after` hook

If a project overlay defined a `## after` section, apply its instructions as the closing step. No overlay ⇒ skip entirely.
