# Appliquer Armature à Armature (dogfooding complet)

**État** : **piste (A') appliquée le 2026-09-09** après un run réel de la piste (B). Le reste (copie doctrinale de `workflow.md`/`persistence-strategy.md`) reste écarté ; ce fichier est conservé comme trace du diagnostic et du verdict.

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

## Ce qui a été fait le 2026-09-09

La piste (B) a été **exécutée pour de vrai** — `/armature:bootstrap` suivi à la lettre par un agent frais dans un worktree isolé, avec interdiction d'écraser l'existant (candidats en collision déviés vers `.bootstrap-candidate/`). Verdict : **le bootstrap complet n'est pas la bonne forme** pour ce repo (frictions F2 et F3 ci-dessous), mais le run a payé immédiatement — il a mis au jour un **bug de rendu en production** (une ligne de tableau gatée soudait le tableau au bloc suivant, dans tout projet bootstrapé sans changelog ; linter vert parce qu'il partageait le défaut).

**Rapatrié** (piste A élargie) : `tools/generate-dashboard.py` (vérifié : `/armature:dashboard` fonctionne désormais sur ce repo — 8 ADR, 8 plans), `tools/session-end-capture.sh` **et son hook `SessionEnd` câblé** dans `.claude/settings.json` (le kit exerce enfin son propre hook, dont la 0.7.0 avait corrigé deux pannes à l'aveugle), `docs/operations.md` (la séquence de release, qui n'existait que comme piège capturé), `docs/architecture.md`, `docs/coding-standards.md`.

**Non rapatrié, délibérément** : `workflow.md` et `persistence-strategy.md` (la copie doctrinale qui dériverait du gabarit — le coût identifié plus haut) ; `claude-code-tooling.md`, `docs/prefs/`, `.env.claude.example`, `docs/README.md` (peu ou pas de contenu utile ici) ; les 9 candidats en collision (`CLAUDE.md`, `claude.sh`, les index et docs existants), l'existant étant meilleur que le gabarit.

**Non appliqué, laissé au choix de l'utilisateur** : le **hook mémoire** (`PreToolUse`). Le kit le recommande fortement et ne se l'applique toujours pas — mais l'activer change le comportement des sessions futures sur ce repo, ce qui est une décision d'usage, pas de dogfooding.

**Frictions du skill relevées par le run** : F1 (le bug ci-dessus) corrigée ; F2 (`claude.sh` écrasé sans condition), F3 (le mode `merge` de la Phase 0 n'était outillé nulle part), F4 (la Phase 3 supposait une cible vierge), F6 (grep TODO ininterprétable sur un repo de gabarits), F7 (« never ship bare » poussant à inventer un plugin) corrigées dans le skill. F5 et F10 (exécution sans canal interactif) versées à [`orchestrated-command-invocation.md`](orchestrated-command-invocation.md).

## Pistes (état au moment de l'arbitrage)

- **(A) Ciblé, sans bootstrap** — n'ajouter que ce qui a une valeur démontrée *aujourd'hui* : les deux scripts `tools/` (auto-capture + dashboard) et `docs/operations.md`. Zéro doublon doctrinal, gain immédiat, réversible.
- **(B) Bootstrap réel en mode `merge`** — faire tourner `/armature:bootstrap` sur ce repo par un agent frais et arbitrer fichier par fichier. Le plus instructif (c'est aussi le test end-to-end du skill qui manque, et le premier exercice réel de la Phase 3 de récolte), le plus risqué pour l'existant.
- **(C) Statu quo assumé, mais écrit** — décider que le repo dogfoode la *machinerie* (ADR/plans/backlog/incidents) et pas la *doc générée*, et le documenter dans `docs/testing.md` pour clore la question.

## Déclencheur

Aucun déclencheur externe : la question revient d'elle-même à chaque release. À traiter au prochain besoin réel de `/armature:dashboard` sur ce repo, ou en même temps que le test end-to-end de `/armature:bootstrap` encore en attente (`CLAUDE.md` § *Where things stand*) — la piste (B) fait les deux d'un coup.

Candidat à une ADR une fois attaqué (le choix A/B/C est une décision de doctrine, avec des conséquences durables sur la maintenance).
