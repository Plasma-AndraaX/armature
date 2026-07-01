---
description: Start a structured reflection on an architectural decision that produces an ADR + its companion plan.
argument-hint: [topic or question to explore]
---

# New architectural decision

The user wants to think through a topic that deserves an ADR (*Architecture Decision Record*): a structuring, non-trivial decision with explicit tradeoffs. You structure the process so the decision is **fully baked before writing**, then produce the ADR + its companion plan following this repo's conventions.

Topic proposed by the user: **$ARGUMENTS**

## When an ADR is justified

An ADR is relevant if **at least two** of these conditions hold:
- The decision touches multiple areas of the code (several modules/layers/features).
- There's more than one credible option, with tradeoffs you'll need to explain later.
- You want a durable trace of the **why**, not just the **what** (that's what the commit is for).
- The decision is irreversible or expensive to revisit (schema migration, permission overhaul, model change).
- The decision breaks an invariant documented in `lessons-*.md`.

If the topic checks **none** of these boxes, say so and propose a lighter alternative (a simple PR, a code comment, an entry in `lessons-*`). **Refuse to write an ADR for a topic that doesn't deserve one** — a swamp of ADRs dilutes the value of all the others.

## Process

### Phase 1 — Frame the problem

Before writing anything, on your own:

- Restate the problem in your own words. If you can't, you haven't understood it — ask questions.
- List the **invariants** and **constraints** (technical, business, deadline, stack).
- Identify **at least 2 credible options**, not just "the obvious one". If you only find one, keep looking: you don't have an ADR, you have a TODO.

### Phase 2 — Explore the terrain

For decisions touching an unfamiliar or wide area:

- Launch `Explore` agents **in parallel** on the affected zones. One sub-topic per agent.
- Ask for **structured** reports with file:line references, not file dumps. Impose a word limit (~500).
- Cross-reference the reports to measure the real impact.
- Check existing `docs/lessons-*.md` and `docs/adr/` — they may already hold part of the answer or document invariants to respect.

**Don't start drafting until you have:**
- A clear picture of the impacted zones and estimated cost.
- The credible options with their respective costs.

### Phase 3 — Go back and forth on tradeoffs

Present the options to the user, for each:

- **What you gain** (concrete positives, not vague).
- **What you pay** (honest costs and risks — no whitewashing).
- **What remains ambiguous** (open questions to settle).

Give your opinion with its reasoning. A neutral "all options are equal" is an abdication — form a point of view. But stay open to being pushed back.

**Don't write the ADR until:**
- All blocking open questions are settled.
- The user has **explicitly** validated the chosen option.
- The *in* and *out* scope is clear.

If the discussion drifts to a new adjacent topic, propose a separate ADR rather than stacking everything into one.

### Phase 4 — Write the ADR

File: `docs/adr/NNNN-kebab-case-title.md`, 4 zero-padded digits. Check `docs/adr/` for the next free number. Follow **`docs/adr/template.md`**.

Frontmatter:
```yaml
---
status: proposed        # moves to accepted once the user validates
date: YYYY-MM-DD
deciders: []
superseded-by:
related-adrs: []
related-plans: [<slug>]
---
```

Sections:
- **Context** — the problem in context. What forces the decision. Brief (200-400 words).
- **Decision** — one or two sentences, active voice. What we choose.
- **Consequences** — *Positive* / *Negative* / *Neutral*. **Be honest about the negatives.** An ADR listing only upsides is suspect.
- **Alternatives considered** — options rejected with a brief reason. Details go in the plan.
- **References** — related ADRs, companion plan (path), external links.

Update `docs/adr/README.md` with the new entry in the index (number, title, status, date).

### Phase 5 — Write the companion plan

File: `docs/plans/<slug>.md` (same slug as the ADR, no date prefix while `in-progress`).

Frontmatter:
```yaml
---
status: in-progress
created: YYYY-MM-DD
settled:
related-adr: NNNN
---
```

Recommended sections:
- **Problem restatement** — the problem in the code's vocabulary (classes, services, tables).
- **Target shape** — target schema, models, interfaces. Code sketch if useful.
- **Impact surface** — layers touched, with file:line where you have them.
- **Implementation lots** — breakdown into independently mergeable PRs, in an order that preserves consistency. **Each lot has an explicit *exit criterion***.
- **Alternatives considered (deeper than the ADR)** — detailed rejection reasoning, with code sketches if relevant.
- **Open questions** — what remains to be settled before starting a given lot.
- **Follow-ups surfaced during implementation** — starts empty, filled in as work progresses (e.g. via `/capture-lessons`).
- **Next actions** — concrete checklist to get started.

Update `docs/plans/README.md` with the new entry in the index.

### Phase 6 — Commit the docs

A **single `docs:` commit** for the ADR, the plan, and both indexes. Don't mix with code. Check `docs/prefs/<login>.md` (if this project uses it) for the user's commit message conventions before writing the commit.

## Rules

- **ADR numbering**: 4 zero-padded digits, next free one in `docs/adr/`.
- **ADR is immutable once `accepted`**: to revisit, write a new ADR that supersedes it (`superseded-by` in the old one's frontmatter).
- **Plan is editable while `in-progress`**; frozen at final cleanup (renamed with `YYYY-MM-DD-` prefix + `status: implemented` or `rejected`).

## What you do NOT do

- Write the ADR before tradeoffs are discussed and open questions settled — you'd be making the decision instead of the user.
- Hide the negatives to sell the chosen decision — the ADR must remain usable under hostile retrospective review, not just to celebrate.
- Mix the ADR and the implementation plan: the ADR is the **what + why**, the plan is the **how**.
- Start implementation right after — Phase 6 ends with the docs commit. Implementation comes in separate commits, possibly split across the plan's lots.
- Write an ADR for a trivial decision or an obvious refactor — overkill, use a simple PR.
- Stack adjacent topics that deserve their own ADR into this one — keep scope tight, propose separate ADRs for related topics.
