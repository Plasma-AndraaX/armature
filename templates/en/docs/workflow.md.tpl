# Workflow — ADR ↔ plan ↔ backlog

**When to use what, and where things that emerge along the way get filed.**

[`persistence-strategy.md`](persistence-strategy.md) says *where* to put things. This document says *when* — the life of a decision, from idea to closure, and how adjacent topics that surface along the way get filed without getting lost.

## The cycle

```
              IDEA / PAIN POINT
                    │
                    ▼
           Is it ready to be
              decided now?
                    │
            ┌───────┴───────┐
           NO               YES
            │                │
            ▼                ▼
        BACKLOG           ADR (proposed)
       <slug>.md              │
            │        ┌────────┼────────┐
            │        ▼        ▼        ▼
            │    accepted  deferred  rejected
            │        │        │         │
            │        ▼    ┌─ wake     └─> done
            │   COMPANION │   trigger
            │      PLAN
            │  (in-progress)
            │        │
            │        ▼
            │  IMPLEMENTATION
            │  (lots shipped one by one)
            │        │
            │        ▼
            │  PLAN implemented
            │  (settled date,
            │   renamed YYYY-MM-DD-…)
            │
            └──> Adjacent things surface during implementation
                 → see § "During implementation" below
```

## Routing a new idea

You have an idea, an observed pain point, user feedback, a code observation. Where does it go?

```
                 NEW IDEA
                     │
                     ▼
        Is it a non-obvious technical fact /
           business rule you just learned?
                     │
                 ┌───┴────┐
                YES       NO
                 │         │
                 ▼         ▼
        lessons-technical /  Does an existing backlog
        lessons-domain       item / in-progress plan
        (dated entry)        already cover this topic?
                                  │
                              ┌───┴───┐
                             YES     NO
                              │       │
                              ▼       ▼
                      Add there    Decision: is it
                      (plan        architectural
                      follow-up,   AND mature?
                      or backlog       │
                      sub-item)    ┌───┴───┐
                                  YES     NO
                                   │       │
                                   ▼       ▼
                                ADR +    Backlog item
                                plan     (see § Granularity
                                (heavy   for the shape: a
                                path)    line, a short file,
                                         or a grouped file)
```

**The golden rule for fresh ideas**:

> *"Will this guide a future decision (= ADR + plan)? Is it a pain point to handle someday (= backlog)? Or is it knowledge not to forget (= lessons-*)?"*

Checks before creating a new item:
- **Duplicate?** Grep the slug or main keyword in `docs/backlog/` and `docs/plans/`. If an adjacent item exists → add to it or as a sub-item of a bundle, **not** a new file.
- **Sub-theme of an existing PRIMARY bundle?** → a line under the PRIMARY rather than a dedicated file (see § Granularity, Pattern 3).

## When to open what

| You have… | You open… | Shape |
|---|---|---|
| An idea / pain point not mature yet, decision not ready | A **backlog item** | `docs/backlog/<slug>.md`, free-form |
| A formal architectural decision to make (alternatives + consequences) | An **ADR** | `docs/adr/NNNN-<slug>.md`, `status: proposed` |
| An ADR just got accepted and you're about to start implementation | A **companion plan** | `docs/plans/<slug>.md`, `status: in-progress`. Renamed `YYYY-MM-DD-<slug>.md` once `implemented`/`rejected` |

The ADR is **short** — it describes *what* is chosen and *why*. The plan is **long** — it carries the *how*, the *detailed alternatives*, the implementation *lots*, and the *living history* of the work.

### Don't pre-assign an ADR number in a backlog item

When a backlog item is a candidate to become an ADR, the temptation is to write in its body *"candidate to become ADR NNNN"*, anticipating the next free number. **Don't.** ADRs open in the order decisions are actually made, not in the order backlog items anticipate them. The number you reserve *today* may be taken by a different ADR *tomorrow*, and your reference silently goes stale.

**Instead**:
- Use a neutral phrasing: *"to become an ADR"*, *"future dedicated ADR"*, *"ADR candidate once tackled"*.
- If you **must** signal a number to orient the reader, add `(provisional number, to reconfirm at opening)`.
- When actually **opening** the ADR, pick the next free one and correct the backlog item at the same time if needed.

## Light path vs heavy path

**Not every topic deserves an ADR + plan.** Most backlog items are **fixes / mini-features** handled in a direct commit (maybe a PR if non-trivial), without ceremony.

| Path | When | Cycle |
|---|---|---|
| **Light** | clear-scope bug, UX tweak, localized tech debt, batch audit, effort < 1 day, localized code change | backlog item → direct fix (PR) → backlog item moves to *Reference (closed)* with "resolved via commit XYZ" |
| **Heavy** | choice between several doctrinal options, effort > 1 day or multiple surfaces, establishes a reusable pattern, the decision itself deserves a trace for future contributors | backlog item → ADR `proposed` → companion plan `in-progress` → lots shipped → plan `implemented` → backlog item as reference |

**Quick test**: *if you can summarize what to do in one sentence and send it as a commit message, it's light. If you need a paragraph to explain why option X beats option Y, it's heavy.*

## Backlog item granularity

The backlog is **not** strictly "one file = one topic". Depending on substance, **3 valid shapes**:

### Pattern 1 — Short individual file (~10-50 lines)

When the fix has a few details worth capturing (exact call site, root cause, alternatives ruled out). One line in the backlog README pointing to this file.

### Pattern 2 — Grouped thematic file (1 file, N sub-items as a list)

When **3+ micro-items** share a theme. **Not one file per sub-item** — a single file with a `- [ ] ...` checklist inside, each line short (~1-3 lines max). One line in the backlog README pointing to the grouped file.

### Pattern 3 — PRIMARY bundle + separate sub-item files

When **each sub-item has its own substance** (50+ useful lines, non-trivial alternatives) and they're attached to a major theme (often a future ADR).

The **PRIMARY** is the bundle's single entry point; each sub-item has its own file, with a banner at the top `> **Sub-item of bundle [<primary>](primary.md)**`. The PRIMARY aggregates the list of sub-items at the top.

### Which pattern to use?

| Substance of each item | Pattern |
|---|---|
| **1-3 lines** are enough to describe the item | **Add a line** to an existing grouped file (Pattern 2). If no theme fits, a short individual file |
| **5-50 lines** of analysis / context | **Individual file** (Pattern 1) |
| **50+ lines** per sub-item, alternatives to explain, tied to a major theme | **PRIMARY bundle + sub-items** (Pattern 3) |

**Rule of thumb**: start simple (a line or an individual file). Promote to a more structured pattern only when the material justifies it.

## During implementation: where do emerging things go?

This is *the* classic doctrine gap. Five cases, five destinations:

| Case | Destination | Precise section |
|---|---|---|
| **Option ruled out by doctrine** ("we decided against it, and here's why") | Stays in the plan | `## Alternatives considered` (with the why) |
| **Sub-question resolved during implementation** | Stays in the plan | `## Open questions` (strike through as `~~resolved~~` + one line) or `## Decision log` (dated entry) |
| **Point to handle later, staying *in the same conversation*** | Stays in the plan | `## Follow-ups surfaced during implementation` — becomes either a Lot N+1, or gets migrated to backlog *when the plan closes* |
| **Independent point, different scope, needs its own cycle** | A dedicated **backlog item** | New `docs/backlog/<slug>.md` headed with `_Surfaced during implementation of [plan for ADR NNNN](...)._` |
| **Point that deserves its own architectural reasoning** | A **new ADR** | Mentioned in the origin plan's `related-adrs:` |

### The golden rule for the last 3 cases (the real gray zone)

> **If the conversation that will eventually resolve this point will be the same one that closes the current plan → stays as a Follow-up.**
> **If it will need fresh reasoning / a new agenda → backlog item.**
> **If it will need a new architectural frame → ADR.**

## What happens to a backlog item promoted to an ADR?

Symmetric to the section above. When a backlog item matures into an ADR + plan, it **doesn't disappear instantly** — it evolves with the ADR's state:

| ADR state | What the backlog item becomes |
|---|---|
| Not yet promoted | Lives normally in the active backlog |
| **ADR `proposed`, opened from the backlog item** | Backlog item **stays active**; add a note `_To convert into ADR NNNN_` in its body |
| **ADR `accepted`, plan `in-progress`** | The **plan becomes the source of truth** for the work. The backlog item remains but becomes a **historical pointer** — work now happens in the plan |
| **ADR `accepted`, plan `implemented`** | Backlog item moves to the **"Reference (closed)"** section of the backlog README, with a banner `**Status**: resolved by [ADR NNNN] + [companion plan]` |
| **ADR `rejected`** | Backlog item returns to its initial active state (or is itself rejected if the substance is judged irrelevant) |
| **ADR `deferred`** | Backlog item stays active as long as the topic is; note "ADR NNNN deferred, wake trigger documented" |

## Closing a plan: mini-checklist

Before moving a plan to `implemented`:

1. [ ] Every Lot in `## Implementation lots` is either ✅ shipped (referenced in `## Progress`), or explicitly **gated future** within the Lot itself.
2. [ ] Every `## Open questions` entry is either resolved (struck through) or explicitly moved to `## Follow-ups`.
3. [ ] Surviving `## Follow-ups surfaced during implementation` entries each have an explicit destination: handled in the final Lot, migrated to a **backlog item** (create the file, reference it here), or explicitly marked *gated future* with a documented trigger.
4. [ ] Frontmatter moves to `status: implemented` + `settled: YYYY-MM-DD`.
5. [ ] File renamed with a date prefix: `git mv <slug>.md YYYY-MM-DD-<slug>.md`. All inbound links updated.
6. [ ] The corresponding entry in [`docs/plans/README.md`](plans/README.md) is updated (`status` + new name).
7. [ ] Non-obvious lessons captured in [`lessons-technical.md`](lessons-technical.md) or `lessons-domain.md`, dated.

An `implemented` plan is **frozen**: its content isn't edited afterward (except typos). It's an archaeological record. To revisit, open a new ADR + plan.

## Special statuses

### ADR `deferred`

The ADR was examined but put to sleep. Wake triggers are documented in the ADR body ("when a CVE shows up", "when a user reports X", etc.). The ADR survives as reference, not re-discussed until a trigger fires.

The companion plan of a `deferred` ADR stays `in-progress` (the plan convention only supports `in-progress | implemented | rejected`). The real status is documented in the ADR's header.

### ADR `superseded`

A newer ADR replaces the old one. The `superseded-by: NNNN` field points to the successor. The old ADR survives as historical reference.

### Plan `rejected`

The plan was opened but the work was never tackled and got abandoned (typically: the ADR went `rejected` or permanently `deferred`). Frontmatter `status: rejected` + `settled: YYYY-MM-DD` + rename `YYYY-MM-DD-<slug>.md`.

## Cheat sheet

- **Plan** = the *how* of an accepted ADR. Long. Alive.
- **ADR** = the *decision*. Short. Frozen once accepted.
- **Backlog item** = a topic *not yet* ready for an ADR, *or* an independent follow-up migrated from a plan.
- **Canonical plan sections** (see [`plans/template.md`](plans/template.md)) — each has its purpose. When a point emerges, ask: "which section does this look like?"
