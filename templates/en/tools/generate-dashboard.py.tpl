#!/usr/bin/env python3
"""Regenerates docs/dashboard.html — track-based overview of ADRs / plans / backlog.

For each existing ADR, the script builds a "track" showing:
  - The decision (ADR + status)
  - The companion plan(s) (matched via `related-adr` frontmatter)
  - The active backlog items that mention this ADR in their text

Anti-false-positive: only *existing* ADRs are matched. Date-prefixed filenames
(`YYYY-MM-DD-...`) are excluded from the filename pattern so they aren't
confused with ADR numbers.

Idempotent: no side effect besides the final write to `docs/dashboard.html`.
Run from the repo root.

Usage: `python3 tools/generate-dashboard.py`
"""

import re
import sys
from collections import defaultdict
from datetime import datetime
from html import escape
from pathlib import Path

# ─── Paths ──────────────────────────────────────────────────────────────
REPO_ROOT = Path(__file__).resolve().parent.parent
ADR_DIR = REPO_ROOT / 'docs' / 'adr'
PLAN_DIR = REPO_ROOT / 'docs' / 'plans'
BACKLOG_DIR = REPO_ROOT / 'docs' / 'backlog'
OUTPUT = REPO_ROOT / 'docs' / 'dashboard.html'
PROJECT_NAME = '{{PROJECT_NAME}}'


# ─── Parsing helpers ────────────────────────────────────────────────────
def existing_adr_numbers():
    """Set of ADR numbers actually present in docs/adr/."""
    out = set()
    for f in ADR_DIR.glob('[0-9]*-*.md'):
        m = re.match(r'^(\d+)-', f.name)
        if m:
            out.add(int(m.group(1)))
    return out


def parse_frontmatter(path):
    """Return (fm_dict, title, body)."""
    text = path.read_text(encoding='utf-8')
    fm, body = {}, text
    if text.startswith('---'):
        end = text.find('\n---', 4)
        if end > 0:
            for line in text[4:end].splitlines():
                if ':' in line:
                    k, v = line.split(':', 1)
                    fm[k.strip()] = v.strip()
            body = text[end + 5:]
    title_m = re.search(r'^# (ADR \d+ — )?(.+?)$', body, re.MULTILINE)
    title = title_m.group(2).strip() if title_m else ''
    return fm, title, body


def find_adr_refs(text, existing):
    """ADR mentions in text, restricted to existing numbers.

    Two patterns:
    - 'ADR NNNN' explicit mention
    - 'NNNN-slug.md' filename (4 digits zero-padded, excludes date-prefixed plans).
    """
    refs = set()
    for m in re.finditer(r'\bADR\s+0*(\d{1,4})\b', text):
        n = int(m.group(1))
        if n in existing:
            refs.add(n)
    for m in re.finditer(r'\b(\d{4})-[a-z][\w-]+\.md\b', text):
        n = int(m.group(1))
        if n in existing and n < 1000:
            refs.add(n)
    return refs


def _strip_markdown(text):
    """Strip basic markdown syntax for plain-text rendering."""
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    text = re.sub(r'`([^`]+)`', r'\1', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    return text.strip().strip('_').strip()


def _truncate(text, limit):
    """Truncate at word boundary, add ellipsis."""
    if len(text) <= limit:
        return text
    return text[:limit].rsplit(' ', 1)[0] + '…'


def _extract_section(text, section_re, limit=320, include_lists=False):
    """Extract content under a `## <section>` heading, joined as one paragraph.

    Stop at the next `## ` heading. Returns up to `limit` chars, markdown-stripped.
    The regex matches the heading; we then consume the rest of that line (parenthetical
    subtitle, etc.) before extracting the body.

    `include_lists=True`: flattens top-level bullet lists into the paragraph stream
    (joined by separators), useful for plans where the substance lives in the list
    after a short intro like "Today: ...".
    """
    m = re.search(section_re, text, re.MULTILINE | re.IGNORECASE)
    if not m:
        return ''
    nl = text.find('\n', m.end())
    start = nl + 1 if nl >= 0 else m.end()
    end_m = re.search(r'\n## ', text[start:])
    body = text[start:start + (end_m.start() if end_m else 2000)]
    # Pull out the first paragraph + (optional) first bullet list as a synthesis
    paragraphs = []
    current = []
    list_items = []
    for line in body.splitlines():
        s = line.strip()
        if not s:
            if current:
                paragraphs.append(' '.join(current)); current = []
            continue
        if s.startswith('>') or s.startswith('|') or s.startswith('```'):
            continue
        is_bullet = s.startswith('- ') or s.startswith('* ') or bool(re.match(r'^\d+\. ', s))
        if is_bullet:
            if include_lists:
                # Strip the bullet marker, accumulate the item text
                stripped = re.sub(r'^(?:[-*]|\d+\.)\s+', '', s)
                list_items.append(stripped)
            # else: skip
            continue
        current.append(s)
    if current:
        paragraphs.append(' '.join(current))
    if not paragraphs and not list_items:
        return ''
    pieces = paragraphs[:1]
    if include_lists and list_items:
        pieces.append(' · '.join(list_items[:4]))  # max 4 bullets to keep it scannable
    joined = _strip_markdown(' — '.join(p for p in pieces if p))
    return _truncate(joined, limit)


def first_paragraph_short(text, limit=140):
    """First non-trivial paragraph after the H1, with markdown stripped."""
    after_h1 = False
    out = ''
    for line in text.splitlines():
        if line.startswith('# '):
            after_h1 = True
            continue
        if not after_h1:
            continue
        s = line.strip()
        if not s or s.startswith('>') or s.startswith('##'):
            continue
        if s.startswith('**Status'):
            continue
        out = s
        break
    return _truncate(_strip_markdown(out), limit)


def summarize_adr(text, limit=280):
    """Summarize an ADR: the ## Decision section (active voice by convention)."""
    decision = _extract_section(text, r'^## Decision\b', limit)
    if decision:
        return decision
    # Fallback: ## Context (first useful sentence)
    return _extract_section(text, r'^## Context\b', limit)


def summarize_plan(text, limit=280):
    """Summarize a plan: the ## Problem restatement section (canonical template).

    On plans, the substance often lives in a list after a short intro like
    "Today (...):"" — so top-level bullets are included in the summary to
    avoid losing the essential part.
    """
    problem = _extract_section(text, r'^## Problem restatement', limit, include_lists=True)
    if problem:
        return problem
    # Fallback: first useful paragraph (non-canonical plans or investigation drafts)
    return first_paragraph_short(text, limit)


def is_resolved(text):
    head = text[:500]
    return bool(re.search(
        r'^>?\s*\*\*(?:Resolved|Closed|Status\s*:\s*resolved)\b'
        r'|^_(?:Resolved|Closed)\b|^✅',
        head, re.MULTILINE | re.IGNORECASE))


def is_primary(text):
    return 'PRIMARY' in text[:500]


def find_subitem_of(text):
    m = re.search(
        r'\*\*Sub-item\s+of\s+bundle\s+\[`?([^\]`]+)`?\]\(([^)]+)\)',
        text[:1500], re.IGNORECASE)
    return m.group(2).strip() if m else None


# ─── Build data model ──────────────────────────────────────────────────
def build():
    existing = existing_adr_numbers()

    adrs = {}
    for f in sorted(ADR_DIR.glob('[0-9]*-*.md')):
        fm, title, body = parse_frontmatter(f)
        num = int(re.match(r'^(\d+)-', f.name).group(1))
        adrs[num] = {
            'num': num,
            'status': fm.get('status', '?'),
            'title': title,
            'summary': summarize_adr(body),
            'file': str(f.relative_to(REPO_ROOT)),
        }

    plans_by_adr = defaultdict(list)
    for f in sorted(PLAN_DIR.glob('*.md')):
        if f.name in ('README.md', 'template.md'):
            continue
        fm, title, body = parse_frontmatter(f)
        related = fm.get('related-adr', '').strip()
        related_adr = int(related) if related.isdigit() else None
        plan = {
            'status': fm.get('status', '?'),
            'related_adr': related_adr,
            'title': title,
            'summary': summarize_plan(body),
            'file': str(f.relative_to(REPO_ROOT)),
            'name': f.name,
        }
        if related_adr is not None:
            plans_by_adr[related_adr].append(plan)

    backlog_all = []
    for f in sorted(BACKLOG_DIR.glob('*.md')):
        if f.name == 'README.md':
            continue
        fm, title, body = parse_frontmatter(f)
        backlog_all.append({
            'name': f.name,
            'file': str(f.relative_to(REPO_ROOT)),
            'title': title,
            'intro': first_paragraph_short(body, 180),
            'resolved': is_resolved(body),
            'primary': is_primary(body),
            'subitem_of': find_subitem_of(body),
            'adr_refs': sorted(find_adr_refs(body, existing)),
        })

    tracks = []
    used_in_track = set()
    for num in sorted(adrs.keys()):
        linked = []
        for b in backlog_all:
            if b['resolved']:
                continue
            if num in b['adr_refs']:
                linked.append(b)
                used_in_track.add(b['name'])
        tracks.append({
            'adr': adrs[num],
            'plans': plans_by_adr.get(num, []),
            'backlog': linked,
        })

    orphans = [b for b in backlog_all
               if not b['resolved']
               and b['name'] not in used_in_track
               and not b['subitem_of']]
    subitems_orphan = [b for b in backlog_all
                       if not b['resolved']
                       and b['name'] not in used_in_track
                       and b['subitem_of']]
    resolved = [b for b in backlog_all if b['resolved']]

    return tracks, orphans, subitems_orphan, resolved


# ─── HTML rendering ────────────────────────────────────────────────────
STATUS_STYLES = {
    'accepted':    ('#16a34a', '#dcfce7', 'Accepted'),
    'implemented': ('#16a34a', '#dcfce7', 'Implemented'),
    'in-progress': ('#2563eb', '#dbeafe', 'In progress'),
    'deferred':    ('#6b7280', '#f3f4f6', 'Deferred'),
    'proposed':    ('#f59e0b', '#fef3c7', 'Proposed'),
    'rejected':    ('#dc2626', '#fee2e2', 'Rejected'),
    '?':           ('#9ca3af', '#f3f4f6', 'Draft'),
}


def badge(status, small=False):
    fg, bg, label = STATUS_STYLES.get(status, STATUS_STYLES['?'])
    cls = 'badge small' if small else 'badge'
    return f'<span class="{cls}" style="color:{fg};background:{bg}">{label}</span>'


def file_link(file, label=None):
    # `file` arrives as a repo-relative path (e.g. "docs/plans/foo.md") but the dashboard
    # itself lives under docs/, so we strip the prefix to get a browser-relative link
    # (otherwise we'd get a duplicated "docs/docs/...").
    href = file[5:] if file.startswith('docs/') else file
    return f'<a class="file" href="{escape(href)}">{escape(label or file.split("/")[-1])}</a>'


CSS = '''<style>
  :root {--bg:#f5f6f8;--surface:#fff;--border:#e3e6eb;--text:#1f2329;--muted:#6b7280;--primary:#3b82f6;--accent:#f59e0b;--radius:8px;}
  *{box-sizing:border-box;} body{margin:0;font:14px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;color:var(--text);background:var(--bg);}
  header{padding:20px 32px;background:var(--surface);border-bottom:1px solid var(--border);position:sticky;top:0;z-index:10;}
  header h1{margin:0;font-size:22px;} header .subtitle{margin-top:4px;color:var(--muted);font-size:13px;}
  .stats{display:flex;gap:24px;margin-top:14px;flex-wrap:wrap;font-size:13px;} .stat strong{font-size:17px;}
  .legend{display:flex;gap:12px;flex-wrap:wrap;font-size:12px;padding:8px 0 0;color:var(--muted);align-items:center;}
  main{padding:24px 32px 64px;max-width:1500px;margin:0 auto;} section{margin-bottom:36px;}
  section>h2{font-size:18px;margin:0 0 16px;padding-bottom:8px;border-bottom:2px solid var(--text);}
  section>h2 .count{color:var(--muted);font-size:13px;font-weight:normal;margin-left:8px;}
  .track{background:var(--surface);border:1px solid var(--border);border-left:4px solid var(--border);border-radius:var(--radius);padding:14px 18px;margin-bottom:14px;display:grid;grid-template-columns:minmax(0,1.2fr) minmax(0,1.4fr) minmax(0,2fr);gap:18px;align-items:start;}
  .track.status-accepted, .track.status-implemented{border-left-color:#16a34a;}
  .track.status-in-progress{border-left-color:#2563eb;} .track.status-deferred{border-left-color:#6b7280;opacity:0.92;}
  .track.status-proposed{border-left-color:#f59e0b;}
  .track-col h4{font-size:11px;text-transform:uppercase;letter-spacing:0.06em;color:var(--muted);margin:0 0 8px;font-weight:600;}
  .adr-block .num{font-family:monospace;font-size:12.5px;color:var(--muted);}
  .adr-block .title{font-weight:600;margin:4px 0 6px;font-size:14px;line-height:1.3;}
  .adr-block .summary{color:var(--muted);font-size:12px;line-height:1.45;margin:0 0 6px;}
  .adr-block .meta{display:flex;gap:8px;align-items:center;font-size:11.5px;flex-wrap:wrap;}
  .plan-block{font-size:13px;} .plan-block .empty{color:var(--muted);font-style:italic;font-size:12px;}
  .plan-block .plan{padding:6px 0;} .plan-block .plan+.plan{border-top:1px dashed var(--border);margin-top:6px;padding-top:8px;}
  .plan-block .title{font-weight:500;font-size:13px;line-height:1.35;}
  .plan-block .summary{color:var(--muted);font-size:11.5px;line-height:1.4;margin:3px 0;}
  .backlog-list{display:flex;flex-direction:column;gap:6px;}
  .backlog-item{background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:8px 10px;font-size:12.5px;line-height:1.4;}
  .backlog-item.subitem{border-style:dashed;opacity:0.85;} .backlog-item.primary{background:#fef9e7;border-color:#f59e0b;}
  .backlog-item .title{font-weight:500;display:block;margin-bottom:3px;} .backlog-item .file{display:inline-block;margin-top:3px;}
  .backlog-item .intro{color:var(--muted);font-size:11.5px;line-height:1.4;margin:3px 0 4px;}
  .backlog-empty{color:var(--muted);font-style:italic;font-size:12px;}
  .badge{font-size:10.5px;font-weight:600;padding:2px 8px;border-radius:10px;text-transform:uppercase;letter-spacing:0.03em;white-space:nowrap;}
  .badge.small{font-size:9.5px;padding:1px 6px;}
  .file{color:var(--primary);text-decoration:none;font-family:monospace;font-size:11px;} .file:hover{text-decoration:underline;}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:10px;}
  .card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:10px 12px;}
  .card.bundle{background:linear-gradient(180deg,#fef9e7 0%,var(--surface) 60%);border-color:var(--accent);}
  .card .title{font-weight:600;font-size:13px;margin-bottom:4px;} .card .intro{color:var(--muted);font-size:12px;line-height:1.4;margin-bottom:4px;}
  details summary{cursor:pointer;user-select:none;font-weight:600;} details summary:hover{color:var(--primary);}
  @media (max-width:1000px){.track{grid-template-columns:1fr;}.track-col h4{margin-top:14px;}}
</style>'''


def render(tracks, orphans, subitems_orphan, resolved):
    tot_accepted = sum(1 for t in tracks if t['adr']['status'] == 'accepted')
    tot_deferred = sum(1 for t in tracks if t['adr']['status'] == 'deferred')
    tot_impl = sum(1 for t in tracks for p in t['plans'] if p['status'] == 'implemented')
    tot_inprog = sum(1 for t in tracks for p in t['plans'] if p['status'] == 'in-progress')
    tot_backlog_in_tracks = sum(len(t['backlog']) for t in tracks)
    primary_orphans = [b for b in orphans if b.get('primary')]

    def track_order(t):
        s = t['adr']['status']
        return (0 if s == 'in-progress' else 1 if s == 'accepted' else 2, int(t['adr']['num']))

    tracks_sorted = sorted(tracks, key=track_order)

    out = ['<!doctype html>', '<html lang="en"><head><meta charset="utf-8">',
           f'<title>{escape(PROJECT_NAME)} — track overview</title>', CSS, '</head><body>']

    out.append(f'''
<header>
  <h1>{escape(PROJECT_NAME)} — track overview</h1>
  <div class="subtitle">Each ADR forms a track: decision + companion plan + backlog items that mention it. <b>Architectural</b> view — for the <b>prioritized tactical list</b>, use <code>/whats-left</code>. State as of {datetime.now().strftime('%Y-%m-%d')}.</div>
  <div class="stats">
    <div class="stat"><strong>{len(tracks)}</strong> ADRs ({tot_accepted} accepted, {tot_deferred} deferred)</div>
    <div class="stat"><strong>{tot_inprog}</strong> plans in-progress · <strong>{tot_impl}</strong> implemented</div>
    <div class="stat"><strong>{tot_backlog_in_tracks}</strong> backlog items linked to an ADR · <strong>{len(primary_orphans)}</strong> ADR-candidate bundle(s) · <strong>{len(resolved)}</strong> in reference</div>
  </div>
  <div class="legend">Legend: {badge('accepted')} {badge('in-progress')} {badge('deferred')} {badge('proposed')}</div>
</header>
<main>''')

    out.append(f'<section><h2>ADR tracks <span class="count">— decision + plan + linked backlog</span></h2>')
    for t in tracks_sorted:
        a = t['adr']
        out.append(f'<article class="track status-{a["status"]}">')
        out.append('<div class="track-col adr-block"><h4>Decision (ADR)</h4>')
        out.append(f'<div class="num">ADR {a["num"]:04d}</div>')
        out.append(f'<div class="title">{escape(a["title"])}</div>')
        if a.get('summary'):
            out.append(f'<div class="summary">{escape(a["summary"])}</div>')
        out.append(f'<div class="meta">{badge(a["status"])} {file_link(a["file"])}</div></div>')
        out.append('<div class="track-col plan-block"><h4>Companion plan(s)</h4>')
        if t['plans']:
            for p in t['plans']:
                summary_html = f'<div class="summary">{escape(p["summary"])}</div>' if p.get('summary') else ''
                out.append(
                    f'<div class="plan"><div class="title">{escape(p["title"])}</div>'
                    f'{summary_html}'
                    f'<div class="meta" style="margin-top:3px">{badge(p["status"], True)} '
                    f'{file_link(p["file"], p["name"])}</div></div>')
        else:
            out.append('<div class="empty">— No companion plan</div>')
        out.append('</div>')
        out.append(
            f'<div class="track-col"><h4>Linked active backlog '
            f'<span style="color:#9ca3af;font-weight:normal;text-transform:none;letter-spacing:0">'
            f'({len(t["backlog"])})</span></h4>')
        if t['backlog']:
            out.append('<div class="backlog-list">')
            for b in t['backlog']:
                cls = 'backlog-item' + (' primary' if b['primary'] else ' subitem' if b['subitem_of'] else '')
                prefix = '⭐ ' if b['primary'] else ('↳ ' if b['subitem_of'] else '')
                intro_html = f'<div class="intro">{escape(b["intro"])}</div>' if b.get('intro') else ''
                out.append(
                    f'<div class="{cls}"><span class="title">{prefix}{escape(b["title"])}</span>'
                    f'{intro_html}'
                    f'{file_link(b["file"], b["name"])}</div>')
            out.append('</div>')
        else:
            out.append('<div class="backlog-empty">— No open backlog item references this ADR</div>')
        out.append('</div></article>')
    out.append('</section>')

    # PRIMARY bundles without an ADR only (= candidates to become their own ADR).
    # Standalone items without an ADR + sub-items of a bundle without an ADR are
    # delegated to /whats-left (prioritized tactical view) — not duplicated here.
    # See .claude/commands/dashboard.md § "Boundary with /whats-left".
    if primary_orphans:
        out.append(
            f'<section><h2>Bundles that are ADR candidates '
            f'<span class="count">— {len(primary_orphans)} PRIMARY bundle(s) without an existing ADR</span></h2>'
            f'<p style="color:var(--muted);font-size:13px;margin:0 0 14px">'
            f'Backlog items promoted to PRIMARY but without (yet) their own ADR. To handle the day '
            f'the ADR that will absorb them is opened.</p>'
            f'<div class="grid">')
        for b in primary_orphans:
            out.append(
                f'<div class="card bundle"><div class="title">⭐ {escape(b["title"])}</div>'
                f'<div class="intro">{escape(b["intro"])}</div>'
                f'<div>{file_link(b["file"], b["name"])}</div></div>')
        out.append('</div></section>')

    out.append(
        f'<section><details><summary><h2 style="display:inline">Reference — closed topics ({len(resolved)}) (click)</h2></summary><div class="grid" style="margin-top:14px">')
    for b in resolved:
        out.append(
            f'<div class="card" style="opacity:0.7">'
            f'<div class="title">✓ {escape(b["title"])}</div>'
            f'<div>{file_link(b["file"], b["name"])}</div></div>')
    out.append('</div></details></section>')

    out.append('</main></body></html>')
    return '\n'.join(out)


# ─── Entry point ───────────────────────────────────────────────────────
def main():
    tracks, orphans, subitems_orphan, resolved = build()
    html = render(tracks, orphans, subitems_orphan, resolved)
    OUTPUT.write_text(html, encoding='utf-8')

    # Stats (stdout)
    print(f"Dashboard regenerated: {OUTPUT}")
    print(f"  {len(tracks)} ADR tracks · "
          f"{sum(len(t['plans']) for t in tracks)} plans · "
          f"{sum(len(t['backlog']) for t in tracks)} backlog items linked to an ADR")
    print(f"  {len(orphans)} active backlog items without an ADR · "
          f"{len(subitems_orphan)} orphan sub-items · "
          f"{len(resolved)} in reference")


if __name__ == '__main__':
    main()
