# Architecture

Comment Armature fonctionne *aujourd'hui*. C'est un **document vivant** — à mettre à jour au fil de l'évolution du système, pas comme un journal historique (pour l'historique, utiliser `git log` ou `docs/adr/`).

> Garder ce document centré sur *ce qui existe*, pas sur *pourquoi ça a été choisi ainsi*. Pour le « pourquoi », renvoyer vers l'ADR concernée dans `docs/adr/` ou une entrée datée de `docs/lessons-*.md`.

## Vue d'ensemble

Armature n'est pas une application : c'est un **plugin Claude Code** dont la charge utile est de la documentation. Il est distribué via un marketplace GitHub (`.claude-plugin/marketplace.json` → `plugin/`), installé chez un utilisateur, puis invoqué par des commandes `/armature:<nom>`. Le skill `/armature:bootstrap` lit un arbre de gabarits bundlé (`plugin/templates/<lang>/`), y substitue trois placeholders, résout deux axes conditionnels, et écrit le résultat dans un projet cible quelconque. Les autres skills (`new-adr`, `capture-lessons`, `review-backlog`, `dashboard`, `document-standards`, `changelog-*`) font ensuite vivre cette documentation au quotidien.

Il n'y a **aucun runtime** : rien ne tourne en continu, il n'y a ni serveur, ni base de données, ni dépendance tierce. Les seules pièces exécutables sont un linter Python 3 (stdlib) et quelques scripts Bash.

## Composants majeurs

### `plugin/` — l'unité distribuable

Le seul dossier réellement livré. Contient `.claude-plugin/plugin.json` (manifeste : nom, `version` — c'est **elle** qui pilote la détection d'update, pas `VERSION`, cf. `lessons-technical.md` — et l'option utilisateur `lang`), `plugin/skills/<nom>/SKILL.md` (huit skills, rédigés en anglais, frontmatter `description` + `disable-model-invocation: true` + `argument-hint` optionnel), et `plugin/templates/`.

### `plugin/templates/en/` et `plugin/templates/fr/` — la charge utile

Deux arbres tenus en **parité structurelle stricte** (mêmes chemins relatifs, mêmes marqueurs conditionnels aux mêmes endroits) ; seule la prose diffère. Un fichier porte le suffixe `.tpl` **ssi** la Phase 5 du bootstrap doit lui faire quelque chose (substituer un `{{PLACEHOLDER}}` ou retirer un marqueur) ; tout le reste est copié octet pour octet (`claude.sh`, `.gitignore`, `.env.claude.example`, les `template.md`, `tools/session-end-capture.sh`). Règle énoncée dans `CONTRIBUTING.md`, liste faisant autorité dans la Phase 5 du skill `bootstrap`.

### `tools/lint-templates.py` — le seul contrôle automatisé

260 lignes, stdlib uniquement. Vérifie (1) l'équilibrage des marqueurs `CHANGELOG-ONLY` / `MEMORYHOOK-ONLY` par fichier, (2) la parité `en`/`fr`, (3) le rendu pour **chaque combinaison** (changelog × memoryhook) : pas de placeholder résiduel, pas de marqueur résiduel, pas de ligne vide dans un tableau, pas d'espace en tête de ligne de tableau, pas de 2+ lignes vides consécutives, pas de tableau soudé au bloc suivant, pas de lien relatif vers un fichier non généré. Ne vérifie **pas** que les skills fonctionnent à l'exécution — cela reste un test manuel (voir `testing.md`).

### `docs/` — le dogfooding

Le kit applique sa propre machinerie à lui-même : `docs/adr/` (8 ADR), `docs/plans/` (compagnons), `docs/backlog/`, `docs/lessons-technical.md`, `docs/incidents/`, `docs/testing.md`. Le format des ADR/plans n'est **pas** dupliqué ici : `docs/adr/README.md` pointe vers `plugin/templates/fr/docs/adr/template.md`.

### Racine — la doc du kit lui-même

`README.md` (pitch utilisateur), `ADAPTING.md` (le pourquoi de chaque choix non évident), `CONTRIBUTING.md`, `CHANGELOG.md` (discipline de release à la main), `VERSION` (cosmétique), `claude.sh` (**variante dogfooding** : `claude --plugin-dir ./plugin`, à ne pas confondre avec le `claude.sh` *généré* qui charge `.env.claude`).

## Modèle de données

Pas de base de données. Le « modèle » est un graphe d'artefacts Markdown reliés par du frontmatter YAML :

```
backlog/<sujet>.md    (pas encore tranché)
        │  mûrit
        ▼
adr/NNNN-<slug>.md    frontmatter: status, date, related-plans
        │  1 ↔ 1
        ▼
plans/<slug>.md       frontmatter: status, related-adr
        │  une fois `implemented`
        ▼
plans/YYYY-MM-DD-<slug>.md   (gelé, record archéologique)
```

Les deux `README.md` index (`adr/`, `plans/`) sont maintenus à la main et sont la vue tabulaire de ce graphe ; `tools/generate-dashboard.py` en produit une vue HTML.

## Flux clés

**1. Génération (`/armature:bootstrap`)** — résoudre la cible → localiser `${CLAUDE_PLUGIN_ROOT}/templates` et choisir la langue → analyser le code existant (agents `Explore` en parallèle) → récolter le contexte hors-code (conversation, documents désignés, `git log`) → poser les questions de cadrage → rendre les gabarits (substitution + résolution des deux axes conditionnels) → commit.

**2. Distribution** — `plugin/.claude-plugin/plugin.json` bumpé, tag poussé sur `origin/master`, marketplace GitHub rafraîchi côté consommateur (`/plugin marketplace update`) **avant** `/plugin update`. Voir `lessons-technical.md` : quatre pièges reviennent à chaque release.

**3. Extension par overlay (tier b, ADR 0007)** — six des skills commencent par chercher `.claude/armature/<commande>.md` dans le projet ; s'il existe, ils exécutent sa section `## before`, injectent ses sections nommées aux `[project anchor: <id>]` déclarés dans le corps du skill, puis exécutent `## after`. Extend-only, opt-in : sans overlay, la commande se comporte exactement comme sa base.

## Préoccupations transverses

- **Parité `en`/`fr`** — toute modification d'un gabarit touche les deux arbres ; `tools/lint-templates.py` le vérifie et c'est la première chose à lancer.
- **Marqueurs conditionnels** — deux axes indépendants (`CHANGELOG-ONLY`, `MEMORYHOOK-ONLY`). Sur une **ligne de tableau** le marqueur reste inline ; autour d'un bloc de prose il peut être seul sur sa ligne. Le rendu absorbe la ligne vide qui suivait un bloc retiré **seulement si** ce bloc était lui-même précédé d'une ligne vide — sinon une ligne de tableau gatée souderait le tableau au bloc suivant.
- **Rien de spéculatif** — plusieurs sujets sont volontairement différés avec un déclencheur de réveil documenté plutôt que construits d'avance (`docs/backlog/contribution-and-extension-model.md`).
- **Le kit ne se rétro-propage pas** — un projet déjà bootstrappé ne reçoit pas les améliorations de gabarit ultérieures (`ADAPTING.md` § limitation connue).
