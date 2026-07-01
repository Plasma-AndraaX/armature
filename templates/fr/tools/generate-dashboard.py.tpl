#!/usr/bin/env python3
"""Régénère docs/dashboard.html — vue d'ensemble par tracks des ADR / plans / backlog.

Pour chaque ADR existante, le script construit un « track » qui montre :
  - La décision (ADR + statut)
  - Le(s) plan(s) compagnon(s) (matchés via le frontmatter `related-adr`)
  - Les items de backlog actifs qui mentionnent cette ADR dans leur texte

Anti-faux-positif : seules les ADR *existantes* sont matchées. Les noms de
fichiers préfixés par une date (`YYYY-MM-DD-...`) sont exclus du pattern
filename pour éviter qu'on les confonde avec des numéros d'ADR.

Idempotent : aucun effet de bord à part l'écriture finale dans
`docs/dashboard.html`. À lancer depuis la racine du dépôt.

Usage : `python3 tools/generate-dashboard.py`
"""

import re
import sys
from collections import defaultdict
from datetime import datetime
from html import escape
from pathlib import Path

# ─── Chemins ────────────────────────────────────────────────────────────
REPO_ROOT = Path(__file__).resolve().parent.parent
ADR_DIR = REPO_ROOT / 'docs' / 'adr'
PLAN_DIR = REPO_ROOT / 'docs' / 'plans'
BACKLOG_DIR = REPO_ROOT / 'docs' / 'backlog'
OUTPUT = REPO_ROOT / 'docs' / 'dashboard.html'
PROJECT_NAME = '{{PROJECT_NAME}}'


# ─── Utilitaires de parsing ─────────────────────────────────────────────
def existing_adr_numbers():
    """Ensemble des numéros d'ADR réellement présents dans docs/adr/."""
    out = set()
    for f in ADR_DIR.glob('[0-9]*-*.md'):
        m = re.match(r'^(\d+)-', f.name)
        if m:
            out.add(int(m.group(1)))
    return out


def parse_frontmatter(path):
    """Retourne (dict_frontmatter, titre, corps)."""
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
    """Mentions d'ADR dans le texte, restreintes aux numéros existants.

    Deux patterns :
    - mention explicite « ADR NNNN »
    - nom de fichier « NNNN-slug.md » (4 chiffres zero-padded, exclut les plans préfixés par une date).
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
    """Retire la syntaxe markdown basique pour un rendu texte brut."""
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    text = re.sub(r'`([^`]+)`', r'\1', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    return text.strip().strip('_').strip()


def _truncate(text, limit):
    """Tronque à une limite de mots, ajoute une ellipse."""
    if len(text) <= limit:
        return text
    return text[:limit].rsplit(' ', 1)[0] + '…'


def _extract_section(text, section_re, limit=320, include_lists=False):
    """Extrait le contenu sous un titre `## <section>`, joint en un paragraphe.

    S'arrête au prochain titre `## `. Retourne jusqu'à `limit` caractères, markdown retiré.
    La regex matche le titre ; on consomme ensuite le reste de cette ligne (sous-titre
    entre parenthèses, etc.) avant d'extraire le corps.

    `include_lists=True` : aplatit les listes à puces de premier niveau dans le flux de
    paragraphes (jointes par des séparateurs), utile pour les plans où la substance vit
    dans la liste après une courte intro type « Aujourd'hui : ... ».
    """
    m = re.search(section_re, text, re.MULTILINE | re.IGNORECASE)
    if not m:
        return ''
    nl = text.find('\n', m.end())
    start = nl + 1 if nl >= 0 else m.end()
    end_m = re.search(r'\n## ', text[start:])
    body = text[start:start + (end_m.start() if end_m else 2000)]
    # Extrait le premier paragraphe + (optionnellement) la première liste à puces comme synthèse
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
                # Retire le marqueur de puce, accumule le texte de l'item
                stripped = re.sub(r'^(?:[-*]|\d+\.)\s+', '', s)
                list_items.append(stripped)
            # sinon : ignorer
            continue
        current.append(s)
    if current:
        paragraphs.append(' '.join(current))
    if not paragraphs and not list_items:
        return ''
    pieces = paragraphs[:1]
    if include_lists and list_items:
        pieces.append(' · '.join(list_items[:4]))  # max 4 puces pour rester scannable
    joined = _strip_markdown(' — '.join(p for p in pieces if p))
    return _truncate(joined, limit)


def first_paragraph_short(text, limit=140):
    """Premier paragraphe non-trivial après le H1, markdown retiré."""
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
        if s.startswith('**Statut'):
            continue
        out = s
        break
    return _truncate(_strip_markdown(out), limit)


def summarize_adr(text, limit=280):
    """Synthèse d'une ADR : la section ## Décision (voix active par convention)."""
    decision = _extract_section(text, r'^## Décision\b', limit)
    if decision:
        return decision
    # Repli : ## Contexte (première phrase utile)
    return _extract_section(text, r'^## Contexte\b', limit)


def summarize_plan(text, limit=280):
    """Synthèse d'un plan : la section ## Reformulation du problème (gabarit canonique).

    Sur les plans, la substance vit souvent dans une liste après une intro courte
    type « Aujourd'hui (...) : » — on inclut donc les puces de premier niveau dans la
    synthèse pour ne pas perdre l'essentiel.
    """
    problem = _extract_section(text, r'^## Reformulation du problème', limit, include_lists=True)
    if problem:
        return problem
    # Repli : premier paragraphe utile (plans non-canoniques ou drafts d'investigation)
    return first_paragraph_short(text, limit)


def is_resolved(text):
    head = text[:500]
    return bool(re.search(
        r'^>?\s*\*\*(?:Résolu|Clos|Statut\s*:\s*(?:résolu|clos))\b'
        r'|^_(?:Résolu|Clos)\b|^✅',
        head, re.MULTILINE | re.IGNORECASE))


def is_primary(text):
    return 'PRINCIPAL' in text[:500]


def find_subitem_of(text):
    m = re.search(
        r'\*\*Sous-item\s+du\s+bundle\s+\[`?([^\]`]+)`?\]\(([^)]+)\)',
        text[:1500], re.IGNORECASE)
    return m.group(2).strip() if m else None


# ─── Construction du modèle de données ──────────────────────────────────
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


# ─── Rendu HTML ─────────────────────────────────────────────────────────
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
    # `file` arrive en chemin relatif au dépôt (ex. "docs/plans/foo.md") mais le
    # dashboard vit lui-même sous docs/, donc on retire le préfixe pour obtenir un
    # lien relatif au navigateur (sinon on aurait un doublon "docs/docs/...").
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

    out = ['<!doctype html>', '<html lang="fr"><head><meta charset="utf-8">',
           f'<title>{escape(PROJECT_NAME)} — vue d\'ensemble par tracks</title>', CSS, '</head><body>']

    out.append(f'''
<header>
  <h1>{escape(PROJECT_NAME)} — vue d'ensemble par tracks</h1>
  <div class="subtitle">Chaque ADR forme un track : décision + plan compagnon + items de backlog qui la mentionnent. Vue <b>architecturale</b> — pour la <b>liste tactique priorisée</b>, utiliser <code>/whats-left</code>. État au {datetime.now().strftime('%Y-%m-%d')}.</div>
  <div class="stats">
    <div class="stat"><strong>{len(tracks)}</strong> ADR ({tot_accepted} accepted, {tot_deferred} deferred)</div>
    <div class="stat"><strong>{tot_inprog}</strong> plans in-progress · <strong>{tot_impl}</strong> implemented</div>
    <div class="stat"><strong>{tot_backlog_in_tracks}</strong> backlog liés à une ADR · <strong>{len(primary_orphans)}</strong> bundle(s) candidat(s) ADR · <strong>{len(resolved)}</strong> en référence</div>
  </div>
  <div class="legend">Légende : {badge('accepted')} {badge('in-progress')} {badge('deferred')} {badge('proposed')}</div>
</header>
<main>''')

    out.append(f'<section><h2>Tracks ADR <span class="count">— décision + plan + backlog liés</span></h2>')
    for t in tracks_sorted:
        a = t['adr']
        out.append(f'<article class="track status-{a["status"]}">')
        out.append('<div class="track-col adr-block"><h4>Décision (ADR)</h4>')
        out.append(f'<div class="num">ADR {a["num"]:04d}</div>')
        out.append(f'<div class="title">{escape(a["title"])}</div>')
        if a.get('summary'):
            out.append(f'<div class="summary">{escape(a["summary"])}</div>')
        out.append(f'<div class="meta">{badge(a["status"])} {file_link(a["file"])}</div></div>')
        out.append('<div class="track-col plan-block"><h4>Plan(s) compagnon(s)</h4>')
        if t['plans']:
            for p in t['plans']:
                summary_html = f'<div class="summary">{escape(p["summary"])}</div>' if p.get('summary') else ''
                out.append(
                    f'<div class="plan"><div class="title">{escape(p["title"])}</div>'
                    f'{summary_html}'
                    f'<div class="meta" style="margin-top:3px">{badge(p["status"], True)} '
                    f'{file_link(p["file"], p["name"])}</div></div>')
        else:
            out.append('<div class="empty">— Pas de plan compagnon</div>')
        out.append('</div>')
        out.append(
            f'<div class="track-col"><h4>Backlog actif lié '
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
            out.append('<div class="backlog-empty">— Aucun item de backlog ouvert ne référence cette ADR</div>')
        out.append('</div></article>')
    out.append('</section>')

    # Bundles PRINCIPAUX hors-ADR uniquement (= candidats à devenir leur propre ADR).
    # Les items isolés sans ADR + les sous-items d'un bundle sans ADR sont délégués
    # à /whats-left (vue tactique priorisée) — pas dupliqués ici. Voir .claude/commands/
    # dashboard.md § « Frontière avec /whats-left ».
    if primary_orphans:
        out.append(
            f'<section><h2>Bundles candidats à devenir ADR '
            f'<span class="count">— {len(primary_orphans)} bundle(s) PRINCIPAL(AUX) sans ADR existante</span></h2>'
            f'<p style="color:var(--muted);font-size:13px;margin:0 0 14px">'
            f'Items de backlog promus en PRINCIPAL mais qui n\'ont pas (encore) leur ADR. À traiter le jour '
            f'où on ouvre l\'ADR qui les absorbera.</p>'
            f'<div class="grid">')
        for b in primary_orphans:
            out.append(
                f'<div class="card bundle"><div class="title">⭐ {escape(b["title"])}</div>'
                f'<div class="intro">{escape(b["intro"])}</div>'
                f'<div>{file_link(b["file"], b["name"])}</div></div>')
        out.append('</div></section>')

    out.append(
        f'<section><details><summary><h2 style="display:inline">Référence — sujets clos ({len(resolved)}) (cliquer)</h2></summary><div class="grid" style="margin-top:14px">')
    for b in resolved:
        out.append(
            f'<div class="card" style="opacity:0.7">'
            f'<div class="title">✓ {escape(b["title"])}</div>'
            f'<div>{file_link(b["file"], b["name"])}</div></div>')
    out.append('</div></details></section>')

    out.append('</main></body></html>')
    return '\n'.join(out)


# ─── Point d'entrée ─────────────────────────────────────────────────────
def main():
    tracks, orphans, subitems_orphan, resolved = build()
    html = render(tracks, orphans, subitems_orphan, resolved)
    OUTPUT.write_text(html, encoding='utf-8')

    # Stats (stdout)
    print(f"Dashboard régénéré : {OUTPUT}")
    print(f"  {len(tracks)} tracks ADR · "
          f"{sum(len(t['plans']) for t in tracks)} plans · "
          f"{sum(len(t['backlog']) for t in tracks)} backlog liés à une ADR")
    print(f"  {len(orphans)} backlog actifs hors ADR · "
          f"{len(subitems_orphan)} sous-items orphelins · "
          f"{len(resolved)} en référence")


if __name__ == '__main__':
    main()
