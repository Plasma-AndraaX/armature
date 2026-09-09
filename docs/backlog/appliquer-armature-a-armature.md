# Appliquer Armature à Armature (dogfooding complet)

**État** : pas tranché. Question récurrente, posée à nouveau le 2026-09-09.

Le kit dogfoode **la moitié** de ce qu'il génère. Le diagnostic ci-dessous est daté du 2026-09-09 (v0.7.0) — inventaire des 26 fichiers que `plugin/templates/en/` produit, confrontés à ce que le repo possède réellement.

## Déjà dogfoodé (9)

`CLAUDE.md`, `docs/adr/` (8 ADR + index + gabarit), `docs/plans/` (9 plans + index + gabarit), `docs/backlog/`, `docs/incidents/` (1 postmortem), `docs/lessons-technical.md`, `docs/testing.md`, `.gitignore`, `claude.sh` — ce dernier en **variante volontairement divergente** (voir plus bas).

## Absent du repo, alors que le kit le génère (10)

| Fichier | Ce que son absence coûte aujourd'hui |
|---|---|
| `tools/session-end-capture.sh` + hook `SessionEnd` | La 0.7.0 vient de **corriger deux pannes réelles de ce script** (« Hook cancelled », rappel jamais affiché) sans qu'il ait jamais tourné sur ce repo. Il n'est éprouvé que chez les consommateurs. |
| `tools/generate-dashboard.py` | `/armature:dashboard` est **inutilisable sur ce repo** — il appelle `python3 tools/generate-dashboard.py`, absent. Avec 8 ADR et 9 plans, c'est précisément le volume où le dashboard sert. |
| `docs/workflow.md` | Le repo **suit** ces règles (routage ADR/plan/backlog, granularité, non-pré-attribution des numéros d'ADR) en lisant `plugin/templates/fr/docs/workflow.md.tpl`. La règle vécue et la règle publiée sont le même fichier — pratique, mais le repo n'a pas de doc de workflow à lui. |
| `docs/persistence-strategy.md` | Idem : « où va quoi » n'existe que sous forme de template. |
| `docs/operations.md` | La procédure de **release/publication** (bump des 5 points dont `plugin.json`, roll du CHANGELOG, tag, `marketplace update` avant `plugin update`, scope projet en CLI) ne vit aujourd'hui que dans une entrée de `lessons-technical.md` — un piège capturé, pas une procédure. |
| `docs/architecture.md` | Rien ne décrit la structure `plugin/skills` ↔ `plugin/templates/<lang>` ↔ `tools/` ↔ `docs/` ailleurs que dans le § Structure de `CLAUDE.md`. |
| `docs/coding-standards.md` | Conventions de rédaction des `SKILL.md` et des templates : dispersées entre `CONTRIBUTING.md` et `CLAUDE.md`. |
| `docs/claude-code-tooling.md` | Inventaire hooks/skills/plugins — le repo n'en a aucun. |
| `docs/README.md` | Index de `docs/`. |
| `docs/prefs/README.md` | Mono-contributeur ; utilité faible mais non nulle (les skills consultent `docs/prefs`). |
| `.env.claude.example` | Pas de secret à charger pour l'instant. |
| Hook mémoire (`.claude/settings.json`) | Le `.claude/settings.json` du repo ne contient qu'un `permissions.allow` vide. Le kit **recommande fortement** ce hook à tous ses utilisateurs et ne se l'applique pas. |

## À ne PAS appliquer (écarté d'avance)

- **`claude.sh`** — la version du repo est une variante *volontaire* (`claude --plugin-dir ./plugin`, dogfooding à chaud) ; celle du template charge `.env.claude` et passe-plat. Un bootstrap l'écraserait et **casserait le dogfooding**. Fusion à la main uniquement (le rappel de fin de session de la 0.7.0, lui, mériterait d'y être porté).
- **`docs/changelog/`** — doublon du `CHANGELOG.md` racine, qui a déjà son format et sa discipline de release.
- **`docs/lessons-domain.md`** — pas de domaine métier riche.

## L'argument pour

Le kit n'a **qu'une seule vérification automatique** (`tools/lint-templates.py`), et elle ne teste que le rendu des templates — pas le comportement des skills (`docs/testing.md` le dit explicitement). S'appliquer à lui-même transformerait le repo en **banc d'essai permanent** : chaque évolution d'un skill s'éprouverait sur le repo qui la porte, au lieu d'attendre un run manuel sur un projet tiers. Les deux exemples du jour sont parlants — le hook `SessionEnd` corrigé sans jamais tourner ici, et la Phase 3 de récolte (ADR 0008) qui ne sera jamais exercée sur ce repo.

## Le coût réel, et pourquoi ce n'est pas tranché

- **Dérive template ↔ copie.** `docs/workflow.md` et `docs/persistence-strategy.md` copiés ici deviennent une *deuxième* source de vérité, qui divergera du template — exactement la limite connue « pas de rétro-propagation » (`ADAPTING.md`), mais subie par le kit lui-même. Un simple pointeur vers `plugin/templates/fr/...` est peut-être plus honnête qu'une copie.
- **Langue.** Le repo est mixte assumé : `CLAUDE.md`/`README.md`/`CHANGELOG.md` en anglais, `docs/` en français. Le bootstrap demande **une** langue — un run naïf produirait une doc incohérente avec l'existant.
- **`merge`, pas génération.** `CLAUDE.md` existe déjà et est **riche** (§ *Where things stand*, conventions de travail). Phase 0 imposerait le chemin `merge` et un arbitrage fichier par fichier — ce n'est pas un bootstrap, c'est une fusion manuelle assistée.
- Une partie des fichiers seraient des coquilles à moitié vides sur un repo qui n'est pas une application (`prefs`, `.env.claude.example`).

## Pistes

- **(A) Ciblé, sans bootstrap** — n'ajouter que ce qui a une valeur démontrée *aujourd'hui* : les deux scripts `tools/` (auto-capture + dashboard) et `docs/operations.md`. Zéro doublon doctrinal, gain immédiat, réversible.
- **(B) Bootstrap réel en mode `merge`** — faire tourner `/armature:bootstrap` sur ce repo par un agent frais et arbitrer fichier par fichier. Le plus instructif (c'est aussi le test end-to-end du skill qui manque, et le premier exercice réel de la Phase 3 de récolte), le plus risqué pour l'existant.
- **(C) Statu quo assumé, mais écrit** — décider que le repo dogfoode la *machinerie* (ADR/plans/backlog/incidents) et pas la *doc générée*, et le documenter dans `docs/testing.md` pour clore la question.

## Déclencheur

Aucun déclencheur externe : la question revient d'elle-même à chaque release. À traiter au prochain besoin réel de `/armature:dashboard` sur ce repo, ou en même temps que le test end-to-end de `/armature:bootstrap` encore en attente (`CLAUDE.md` § *Where things stand*) — la piste (B) fait les deux d'un coup.

Candidat à une ADR une fois attaqué (le choix A/B/C est une décision de doctrine, avec des conséquences durables sur la maintenance).
