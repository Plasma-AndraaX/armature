#!/usr/bin/env python3
"""Consistency checks for claude-project-kit's templates/ tree.

Not generated into bootstrapped projects — this is a maintenance tool for
the kit itself. Run before committing a change to templates/ or to
bootstrap-claude-env.md:

    python3 tools/lint-templates.py

Checks:
1. Structural parity between templates/<lang>/ variants: same set of
   relative file paths in every language directory.
2. Every FULL-ONLY / MINIMAL-ONLY / CHANGELOG-ONLY marker is balanced
   (open == close) within each file.
3. Rendering each file for every (profile, changelog) combination never
   leaves a residual {{PLACEHOLDER}}, a residual marker, or a blank line
   sitting between two Markdown table rows (which breaks the table).

Exits non-zero with a printed report if anything fails.
"""
import os
import re
import sys
from pathlib import Path

KIT = Path(__file__).resolve().parent.parent
TPL_ROOT = KIT / 'templates'

PLACEHOLDERS = {
    '{{PROJECT_NAME}}': 'Widgetizer',
    '{{PROJECT_ONE_LINER}}': 'A small widget API + web demo',
    '{{PRIMARY_STACK}}': 'Node.js / TypeScript (Express backend), npm',
}

ALL_TAGS = ('FULL', 'MINIMAL', 'CHANGELOG', 'MEMORYHOOK')

MINIMAL_SKIP_DIRS = {'adr', 'plans', 'prefs', 'changelog', 'incidents'}
MINIMAL_SKIP_FILES = {'workflow.md.tpl', 'claude-code-tooling.md.tpl', 'lessons-domain.md.tpl', 'testing.md.tpl'}
MINIMAL_SKIP_COMMANDS = {'new-adr.md', 'capture-lessons.md', 'whats-left.md', 'dashboard.md',
                         'changelog-capture.md', 'changelog-draft.md'}
CHANGELOG_PATH_MARKERS = ('docs/changelog', 'dot-claude/commands/changelog-capture.md',
                          'dot-claude/commands/changelog-draft.md')


def check_marker_balance(errors):
    for f in sorted(TPL_ROOT.rglob('*')):
        if f.is_dir():
            continue
        text = f.read_text(encoding='utf-8')
        for tag in ALL_TAGS:
            open_n = text.count(f'<!-- {tag}-ONLY -->')
            close_n = text.count(f'<!-- /{tag}-ONLY -->')
            if open_n != close_n:
                errors.append(f'{f.relative_to(KIT)}: unbalanced {tag}-ONLY markers '
                               f'(open={open_n}, close={close_n})')


def check_lang_parity(errors):
    langs = sorted(p.name for p in TPL_ROOT.iterdir() if p.is_dir())
    rel_sets = {}
    for lang in langs:
        rel_sets[lang] = {str(p.relative_to(TPL_ROOT / lang)) for p in (TPL_ROOT / lang).rglob('*') if p.is_file()}
    if len(langs) < 2:
        return
    base_lang, base_set = langs[0], rel_sets[langs[0]]
    for lang in langs[1:]:
        missing = base_set - rel_sets[lang]
        extra = rel_sets[lang] - base_set
        for m in sorted(missing):
            errors.append(f'templates/{lang}/{m}: missing (present in templates/{base_lang}/)')
        for e in sorted(extra):
            errors.append(f'templates/{lang}/{e}: extra (not present in templates/{base_lang}/)')


def strip_markers(text, active_tags):
    for tag in ALL_TAGS:
        if tag in active_tags:
            # Symmetric strip: a marker that opens a line (before a table row, or on its
            # own line) takes its trailing space with it; a marker that closes a line takes
            # its leading space. Markers mid-prose keep the surrounding spaces intact.
            text = re.sub(rf'(?m)^<!-- {tag}-ONLY -->[ \t]+', '', text)
            text = re.sub(rf'(?m)[ \t]+<!-- /{tag}-ONLY -->[ \t]*$', '', text)
            text = text.replace(f'<!-- {tag}-ONLY -->', '').replace(f'<!-- /{tag}-ONLY -->', '')
        else:
            text = re.sub(rf'[ \t]*<!-- {tag}-ONLY -->.*?<!-- /{tag}-ONLY -->[ \t]*\n?', '', text, flags=re.DOTALL)
    return text


def substitute(text):
    for k, v in PLACEHOLDERS.items():
        text = text.replace(k, v)
    return text


def check_broken_tables(text):
    lines = text.split('\n')
    problems = []
    for i in range(len(lines) - 2):
        if lines[i].lstrip().startswith('|') and lines[i + 1].strip() == '' and lines[i + 2].lstrip().startswith('|'):
            problems.append(f'blank line inside table near: {lines[i][:60]!r}')
    return problems


def gen_path(rel_str):
    """A templates/<lang>/-relative path -> the path it's generated to in a project
    (drop the .tpl suffix, map dot-claude/ -> .claude/)."""
    p = rel_str[:-4] if rel_str.endswith('.tpl') else rel_str
    if p == 'dot-claude':
        return '.claude'
    if p.startswith('dot-claude/'):
        return '.claude/' + p[len('dot-claude/'):]
    return p


def is_skipped(parts, rel_str, profile, changelog):
    """True if this template file is NOT generated for the given (profile, changelog)."""
    if profile == 'minimal':
        if len(parts) > 1 and parts[1] in MINIMAL_SKIP_DIRS:
            return True
        if parts[-1] in MINIMAL_SKIP_FILES:
            return True
        if parts[0] == 'tools':
            return True
        if len(parts) > 2 and parts[0] == 'dot-claude' and parts[1] == 'commands' and parts[2] in MINIMAL_SKIP_COMMANDS:
            return True
    if not changelog and any(rel_str.startswith(m) for m in CHANGELOG_PATH_MARKERS):
        return True
    return False


def check_leading_space_tables(text):
    """A rendered table row must start with `|`, never a stray leading space left by a
    marker strip (see strip_markers)."""
    problems = []
    for line in text.split('\n'):
        if re.match(r'[ \t]+\|', line):
            problems.append(f'leading space before table row: {line[:60]!r}')
    return problems


LINK_RE = re.compile(r'\[[^\]]*\]\(([^)]+)\)')


def check_dead_links(text, src_gen, all_gen, rendered_gen):
    """Flag a relative link whose target IS a kit-template file but is NOT generated in
    this profile (e.g. a link to adr/ from a Minimal render). Targets that aren't kit
    templates at all (external URLs, ADAPTING.md, runtime-only files) are ignored — the
    check only knows about the template tree, not what a project adds later."""
    problems = []
    for target in LINK_RE.findall(text):
        t = target.split('#')[0].strip()
        if not t or t.startswith(('http://', 'https://', 'mailto:')):
            continue
        resolved = os.path.normpath(os.path.join(os.path.dirname(src_gen), t)).replace('\\', '/')
        if resolved in all_gen and resolved not in rendered_gen:
            problems.append(f'link to a file not generated in this profile: {target}')
    return problems


def check_rendering(errors):
    langs = sorted(p.name for p in TPL_ROOT.iterdir() if p.is_dir())
    base_combos = [('full', True), ('full', False), ('minimal', False)]
    combos = [(p, c, m) for (p, c) in base_combos for m in (True, False)]
    for lang in langs:
        tpl = TPL_ROOT / lang
        files = [f for f in sorted(tpl.rglob('*')) if f.is_file()]
        # every template file as the path it'd generate to — used to tell a "link to a
        # kit file skipped in this profile" (flag) from a "link to a non-kit file" (ignore).
        all_gen = {gen_path(str(f.relative_to(tpl)).replace('\\', '/')) for f in files}
        for profile, changelog, memoryhook in combos:
            active_tags = {'FULL'} if profile == 'full' else {'MINIMAL'}
            if changelog:
                active_tags.add('CHANGELOG')
            if memoryhook:
                active_tags.add('MEMORYHOOK')
            rendered_gen = {gen_path(str(f.relative_to(tpl)).replace('\\', '/'))
                            for f in files
                            if not is_skipped(f.relative_to(tpl).parts,
                                              str(f.relative_to(tpl)).replace('\\', '/'), profile, changelog)}
            for f in files:
                rel = f.relative_to(tpl)
                parts = rel.parts
                rel_str = str(rel).replace('\\', '/')
                if is_skipped(parts, rel_str, profile, changelog):
                    continue

                text = substitute(strip_markers(f.read_text(encoding='utf-8'), active_tags))
                label = f'{lang}/{profile}/changelog={changelog}/memoryhook={memoryhook}:{rel_str}'
                # Backtick-wrapped mentions (e.g. `{{PROJECT_NAME}}`) are docs explaining the
                # convention (see propose-kit-improvement.md), not an unresolved placeholder.
                if re.search(r'(?<!`)\{\{[A-Z_]+\}\}(?!`)', text):
                    errors.append(f'{label}: residual placeholder')
                # Only the real marker-comment form counts; bare mentions like `FULL-ONLY`
                # in prose (documenting the convention) are not a residual marker.
                if re.search(r'<!--\s*/?\s*(FULL|MINIMAL|CHANGELOG|MEMORYHOOK)-ONLY\s*-->', text):
                    errors.append(f'{label}: residual profile marker')
                for p in check_broken_tables(text):
                    errors.append(f'{label}: {p}')
                for p in check_leading_space_tables(text):
                    errors.append(f'{label}: {p}')
                for p in check_dead_links(text, gen_path(rel_str), all_gen, rendered_gen):
                    errors.append(f'{label}: {p}')


def main():
    errors = []
    check_marker_balance(errors)
    check_lang_parity(errors)
    check_rendering(errors)

    if errors:
        print(f'lint-templates: {len(errors)} problem(s) found\n')
        for e in errors:
            print(' -', e)
        return 1
    print('lint-templates: OK — marker balance, lang parity, and rendering all clean.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
