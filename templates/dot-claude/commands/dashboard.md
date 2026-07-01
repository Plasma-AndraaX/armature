---
description: Regenerates docs/dashboard.html — architectural view by tracks of ADR ↔ plan ↔ backlog. For the prioritized tactical list, use /whats-left.
---

# Dashboard

Regenerates `docs/dashboard.html`, which presents the current ADR ↔ plans ↔ backlog state as **tracks**: one row per ADR, with its companion plan and the backlog items that mention it.

## Boundary with `/whats-left`

The two commands may look similar — they parse the same sources. The functional boundary:

| `/dashboard` | `/whats-left` |
|---|---|
| **Architectural** view: *"how is the system structured?"* | **Tactical** view: *"what do I work on now?"* |
| Persistent HTML to keep open in a tab | Ephemeral markdown in the conversation |
| ADR tracks + their linked backlog + ADR-candidate bundles | Prioritized list of isolated items, hot items, functional gaps |
| **Includes**: ADR tracks with linked backlog, orphan PRIMARY bundles (ADR candidates), reference (closed) | **Includes**: active standalone items, orphan sub-items, next-step suggestion |
| **Excludes**: standalone items without an ADR, orphan sub-items (delegated to `/whats-left`) | **Excludes**: the ADR ↔ plan mechanics themselves |

Concretely: an active backlog item with no ADR to its name and not part of a PRIMARY bundle shows up in `/whats-left` but **not** in the dashboard. Conversely, the ADR ↔ plan relational structure is invisible in `/whats-left` but central to the dashboard.

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
