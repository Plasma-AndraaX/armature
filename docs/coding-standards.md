# Conventions de code

Le style et les conventions de nommage réellement en vigueur dans Armature — indentation, nommage, formatage, linting. **Document vivant** — à mettre à jour au fil de l'adoption de nouvelles conventions, ou quand un passage ultérieur détecte une dérive.

> Garder ce document centré sur *quelle* est la convention et *comment* elle est appliquée, pas sur le *pourquoi*. Si un choix de style est une décision architecturale délibérée, référencer l'ADR concernée ou une entrée datée de `docs/lessons-technical.md` plutôt que d'expliquer le raisonnement ici.

> Pour (re)générer une proposition de conventions selon la stack (projet neuf, ajout d'un langage, actualisation) : lancer la commande `/armature:document-standards`.

## Vue d'ensemble

Codebase **hétérogène**, mais très déséquilibré : l'essentiel du dépôt est du **Markdown** (prose + gabarits `.tpl`), avec un seul script **Python 3** et une poignée de scripts **Bash**. Les conventions les plus structurantes de ce projet ne sont donc pas des conventions de code au sens habituel, mais des conventions de *contenu* (parité `en`/`fr`, marqueurs conditionnels, suffixe `.tpl`). Une sous-section par zone ci-dessous.

Aucun linter ni formatter tiers n'est configuré (pas de `.editorconfig`, pas de `ruff`/`black`/`shellcheck`, pas de CI) : les conventions ci-dessous sont **observées dans le code**, pas déclarées par un outil.

## Conventions

### Markdown — prose (`docs/`, racine)

- **Langue** : français pour la doc du dépôt (`docs/`, `README.md`, `CLAUDE.md`) ; anglais pour `CONTRIBUTING.md` et pour les `SKILL.md` du plugin.
- **Longueur de ligne** : pas de limite dure ; les paragraphes sont écrits en une ligne longue (pas de wrap manuel), sauf dans les messages de commit (~72 colonnes).
- **Titres** : hiérarchie `#` / `##` / `###`, un seul `#` par fichier.
- **Emphase** : `**gras**` pour le mot-clé porteur, `*italique*` pour les nuances, `` `code` `` pour tout chemin, nom de fichier, commande ou identifiant.
- **Liens** : relatifs, toujours sous la forme ``[`chemin/fichier.md`](chemin/fichier.md)``.
- **Tableaux** : utilisés pour tout mapping (question → doc, artefact → rôle). Une ligne vide dans un tableau le casse — voir la règle des marqueurs ci-dessous.
- **Datation** : `YYYY-MM-DD` partout (frontmatter, `_Captured …._`, préfixes de fichiers de plans gelés).

### Markdown — gabarits (`plugin/templates/<lang>/`)

- **Suffixe `.tpl` ssi** la Phase 5 du bootstrap doit agir sur le fichier (placeholder à substituer et/ou marqueur à retirer). Tout le reste est copié octet pour octet et ne prend pas le suffixe. Liste faisant autorité : Phase 5 de `plugin/skills/bootstrap/SKILL.md`.
- **Placeholders** : `{{PROJECT_NAME}}`, `{{PROJECT_ONE_LINER}}`, `{{PRIMARY_STACK}}` — majuscules, doubles accolades, pas d'autre placeholder.
- **Marqueurs conditionnels** : `<!-- CHANGELOG-ONLY -->` … `<!-- /CHANGELOG-ONLY -->` et `<!-- MEMORYHOOK-ONLY -->` … `<!-- /MEMORYHOOK-ONLY -->`. Sur une **ligne de tableau**, le marqueur reste **inline** sur la même ligne que la ligne de tableau. Autour d'un bloc de prose multi-lignes, un marqueur seul sur sa ligne est admis.
- **Parité stricte `en`/`fr`** : mêmes chemins relatifs, mêmes marqueurs aux mêmes endroits ; seule la prose diffère. Les clés de frontmatter YAML (`status`, `date`, `related-adr`, `related-plans`) restent **en anglais** dans toutes les langues.

### Python (`tools/*.py`, `plugin/templates/*/tools/*.py.tpl`)

- **Indentation** : 4 espaces, jamais de tabulation.
- **Guillemets** : simples (`'…'`) par défaut ; doubles réservés aux chaînes contenant une apostrophe et aux f-strings de regex.
- **Nommage** : `snake_case` pour fonctions et variables, `MAJUSCULES` pour les constantes de module, noms de fichiers en `kebab-case` (`lint-templates.py`, `generate-dashboard.py` — ce sont des scripts, pas des modules importables).
- **Imports** : stdlib uniquement, un import par ligne, `from pathlib import Path` pour tous les chemins (pas de `os.path`).
- **Docstring de module** en tête, décrivant ce que le script vérifie/produit et comment le lancer.
- **Structure** : shebang `#!/usr/bin/env python3`, fonctions au niveau module, un `main()` qui accumule les erreurs dans une liste et sort en non-zéro avec un rapport imprimé.
- **Linter / formatter** : aucun.

### Bash (`claude.sh`, `tools/*.sh`)

- Shebang `#!/usr/bin/env bash`, puis `set -euo pipefail`.
- En-tête de commentaires expliquant à quoi sert le script et ce avec quoi il ne faut pas le confondre.
- Résolution du répertoire du script via `here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`.
- Toutes les expansions de variables entre guillemets ; `exec` pour passer la main au process final.
- **Linter / formatter** : aucun (pas de `shellcheck` configuré).

### JSON (`.claude-plugin/*.json`, `.claude/settings.json`)

- Indentation 2 espaces, pas de commentaires (JSON strict), fichier terminé par un saut de ligne.

## Application

Rien n'est appliqué automatiquement : pas de CI, pas de hook pre-commit, pas d'étape de lint bloquante. Le seul garde-fou est `python3 tools/lint-templates.py`, à lancer **à la main** après toute modification de `plugin/templates/` ou du skill `bootstrap` — c'est une convention sociale rappelée dans `CLAUDE.md` et `CONTRIBUTING.md`, pas une contrainte outillée. Le reste (style Python, style Bash, style Markdown) est purement conventionnel, tenu par relecture.
