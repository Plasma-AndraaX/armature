---
description: Regenerates docs/dashboard.html — architectural view by tracks of ADR ↔ plan ↔ backlog. For the prioritized tactical list, use /review-backlog.
disable-model-invocation: true
---

# Dashboard

Regenerates `docs/dashboard.html`, which presents the current ADR ↔ plans ↔ backlog state as **tracks**: one row per ADR, with its companion plan and the backlog items that mention it.

## Project overlay

Before anything else, check whether this project provides an overlay for this command at `.claude/armature/dashboard.md` (relative to the project root).

- **If it exists**, read it and announce: "**Surcharge projet active** (`.claude/armature/dashboard.md`)". It holds named markdown sections that extend this command:
  - `## before` / `## after` — reserved lifecycle hooks: run `## before` now (before the process below), and `## after` at the very end.
  - a section whose name matches a `[project anchor: <id>]` marker placed in this skill — inject its content at that marker's location.
  - any section matching neither a reserved hook nor a declared anchor: ignore it.
  - Execute the `## before` section now if present.
- **If it does not exist**, proceed normally — this command behaves exactly as its base, with nothing injected.

## Boundary with `/review-backlog`

The two commands may look similar — they parse the same sources. The functional boundary:

| `/dashboard` | `/review-backlog` |
|---|---|
| **Architectural** view: *"how is the system structured?"* | **Tactical** view: *"what do I work on now?"* |
| Persistent HTML to keep open in a tab | Ephemeral markdown in the conversation |
| ADR tracks + their linked backlog + ADR-candidate bundles | Prioritized list of isolated items, hot items, functional gaps |
| **Includes**: ADR tracks with linked backlog, orphan PRIMARY bundles (ADR candidates), reference (closed) | **Includes**: active standalone items, orphan sub-items, next-step suggestion, unfiled material from the current conversation (📥) |
| **Excludes**: standalone items without an ADR, orphan sub-items (delegated to `/review-backlog`), anything not yet filed — a persistent page only reflects what is written | **Excludes**: the ADR ↔ plan mechanics themselves |

Concretely: an active backlog item with no ADR to its name and not part of a PRIMARY bundle shows up in `/review-backlog` but **not** in the dashboard. Conversely, the ADR ↔ plan relational structure is invisible in `/review-backlog` but central to the dashboard.

## Steps

1. **Run**:

   ```bash
   python3 tools/generate-dashboard.py
   ```

   The script is idempotent: it parses `docs/{adr,plans,backlog}/`, detects links between elements via frontmatters + `ADR NNNN` text mentions, and writes `docs/dashboard.html`. No side effect beyond that write.

2. **Show the script's output** to the user (stats: number of tracks, linked backlog, orphans, in reference).

3. **Sanity-check the HTML**:
   ```bash
   wc -l docs/dashboard.html
   grep -c 'class="track"' docs/dashboard.html
   ```

4. **Propose a commit** for the regenerated file — direct commit if this project treats doc-only regeneration as trivial (check `docs/prefs/<login>.md` or ask), otherwise a normal PR:
   ```bash
   git add docs/dashboard.html
   git commit -m "docs(dashboard): regenerate overview"
   ```

> `[project anchor: dashboard-delivery]` — if a project overlay defines a `## dashboard-delivery` section, use it for this delivery/commit step instead of the generic step 4 above (e.g. send the file to the user first, then a project-specific commit/push doctrine).

## When to run this skill

- After a session that touched several ADRs, plans, or backlog items (the dashboard drifts otherwise).
- When the user asks to "regenerate the dashboard", "refresh the overview", or similar.
- At the end of a big documentation cleanup.

The dashboard is **static** — it has no automatic regeneration. This skill is the explicit way to keep it current.

## Script

`tools/generate-dashboard.py` is versioned. If you see unexpected behavior (false-positive ADR link, misclassified item, etc.):

1. Read the source to identify the relevant function (`find_adr_refs`, `is_resolved`, `is_primary`, `find_subitem_of`).
2. Propose a fix in the script itself + a mental test against the observed cases.
3. Verify the regenerated HTML confirms the fix.

Known patterns:
- Date-prefixed plan filenames (`YYYY-MM-DD-slug.md`) must **not** be interpreted as ADRs — the regex already filters by zero-padded numbers restricted to the set of *existing* ADRs built at script startup.
- Literal textual mentions of an ADR ("ADR 0011") are taken at face value — if a backlog item says "candidate to become ADR 0011", it'll be linked to 0011 even if that intent is stale. The fix in that case is on the backlog side (correct the candidate number), not the script.

### Final — project `after` hook

If a project overlay defined a `## after` section, apply its instructions as the closing step. No overlay ⇒ skip entirely.
