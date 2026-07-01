---
status: in-progress
created: YYYY-MM-DD
settled:
related-adr: NNNN
---

# Plan — <title> (companion to ADR NNNN)

Companion to [ADR NNNN](../adr/NNNN-<slug>.md). Captures *how* it's implemented, *which* alternatives were explored, and *what* remains open.

> **For section grammar** see [`docs/workflow.md`](../workflow.md) — each section has a precise purpose. When a point emerges during implementation, ask: "which section does this look like?"

## Problem restatement

Restate the problem in the vocabulary of the code (concrete files, constraints, entities). Anchors the plan in reality — not a copy-paste of the ADR's Context.

## Target shape

What the target looks like. Diagram, domain model sketch, URL schema, etc. Can quote code excerpts or pseudo-code.

## Impact surface

### Backend
### Frontend
### Data & migrations
### Documentation

Inventory of the layers touched. Important for scoping Lots and estimating effort.

## Implementation lots

Breakdown into independent Lots where possible. Each Lot has a measurable **exit criterion**.

### Lot 1 — <title>
- Bullet 1
- Bullet 2
- **Exit criterion**: *…what makes this Lot done…*

### Lot 2 — <title>
- …

### Lot N (optional, gated future) — <title>
- Documented wake trigger if applicable.

## Alternatives considered (deeper than the ADR)

Options ruled out **by doctrine** ("we decided against it"), with the why. More detailed than the ADR's *Alternatives* section.

### α — Option name
Why ruled out.

### β — Option name
Why ruled out.

## Open questions

Questions open at the time the plan was opened. Strike through as `~~resolved~~` as implementation progresses, with a line explaining the resolution.

- **Q1 — <statement>**: *…context / direction…*
- **Q2 — <statement>**: *…*

## Progress

Table or list tracking what's been shipped. Mention SHA / PR / date for each Lot.

| Lot | SHA | Date | Notes |
|---|---|---|---|
| Lot 1 — … | `abc1234` | YYYY-MM-DD | … |

## Follow-ups surfaced during implementation

Adjacent points discovered during implementation. Three possible outcomes (see [`workflow.md`](../workflow.md) § *During implementation*):
- handled in a Lot N+1 of **this** plan,
- migrated to a dedicated **backlog item** (create the file, reference it here),
- resulted in a **new ADR** (reference in the parent ADR's `related-adrs` + here).

When the plan closes, each surviving follow-up **must have an explicit destination**.

- **<follow-up 1>** — *…description / destination…*

## Decision log

Dated trace of decisions made during the work. Useful to reconstruct "why choice X at time Y" months later.

- **YYYY-MM-DD** — *decision X made for reason Y.*

## Next actions

Checklist for immediate or inter-Lot actions. Checked off as you go. At closure, all must be ✅ or explicitly pointed to a destination (Lot, backlog, other ADR).

- [ ] *immediate action…*
- [ ] *decision to make in Lot N…*

---

## At plan closure

See [`docs/workflow.md`](../workflow.md) § *Closing a plan: mini-checklist*. In short:

1. All Lots shipped (or explicit *gated future*) ✓
2. All open questions resolved or migrated ✓
3. Surviving follow-ups migrated to backlog ✓
4. Frontmatter `status: implemented` + `settled: YYYY-MM-DD` ✓
5. Rename `YYYY-MM-DD-<slug>.md` + update inbound links ✓
6. `docs/plans/README.md` entry updated ✓
7. Lessons captured in `lessons-*` ✓
