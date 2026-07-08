---
status: in-progress
created: 2026-07-08
settled:
related-adr: 0007
---

# Plan — Mécanisme d'extension des commandes (tier b) — compagnon de l'ADR 0007

Compagnon de [l'ADR 0007](../adr/0007-mecanisme-extension-tier-b.md). Capture *comment* le mécanisme extend-first se construit, *quelles* formes ont été explorées, et *ce qui* reste ouvert. La direction est fixée par l'ADR ; **le design concret est délibérément ici** (pas dans l'ADR immuable) et se valide par un prototype avant généralisation.

## Reformulation du problème

Les skills de base vivent sous `plugin/skills/<nom>/SKILL.md`, partagées, lues depuis `${CLAUDE_PLUGIN_ROOT}`. Aujourd'hui, un projet qui veut les spécialiser les **forke** (tier c) — Holoon en a 6, dupliquées de la base (voir le diagnostic 2026-07-08). On veut : **base au plugin + surcouche au projet**, injectée à des points prévus, en mode extension.

## Forme cible (à valider au Lot 1 — non figée)

- **Overlay projet** : **un fichier par commande** (Q1 résolue), à **`.claude/armature/<nom>.md`**, committé, avec une **section markdown par point d'injection** (`## before`, `## after`, `## <ancrage>`). Sous `.claude/` et namespacé par le plugin ; **jamais** `.claude/hooks/` (réservé aux hooks Claude Code natifs — concept distinct).
- **Dispatch** : chaque skill de base commence par une clause — « si l'overlay projet existe, lis-le et applique ses injections aux points ci-dessous ; annonce *surcharge projet active* au démarrage ».
- **Points d'injection = deux granularités d'un même mécanisme** (un point identifié + un bloc projet qui le remplit) :
  - **Hooks lifecycle — la forme dominante** : `before` / `after` / `end` (et éventuels `before-<phase>`). **Universels** (toute commande en a, zéro prévoyance de l'auteur de la base) et **plus fiables** que l'injection mid-flow — un prepend/append est robuste pour le modèle, un *splice* au milieu l'est moins (dé-risque le bémol « dispatch mou », cf. Q3).
  - **Ancrages nommés mid-flow — le sous-ensemble sémantique** : là où le projet doit remplir un *trou précis* au milieu du flux (une cellule de table, un champ), la base déclare un ancrage nommé. Coûte de la prévoyance → réservé aux cas où un hook `before`/`after` ne suffit pas.
- **Correspondance avec le diagnostic** (les 4 natures) :
  1. **Étapes additionnelles** (`changelog-draft` locales/metadata/captures, `dashboard` delivery+push) → **hook `after`/`end`** — la majorité des besoins Holoon, capturée proprement.
  2. **Format de sortie surchargeable** (`dashboard`, `changelog-draft`) → hook `after` ou ancrage selon la finesse voulue.
  3. **Cibles/exemples domaine-stack** (`new-adr` zones, `capture-lessons` table) → **ancrage mid-flow**, ou tier (a) via `CLAUDE.md`.
  4. **Détection projet-spécifique** (`whats-left` grep) → ancrage mid-flow (« point clé »).
- **Ce que les hooks ne font pas** : `before`/`after` *enrobent*, ils ne *modifient* pas un pas du milieu. Changer *comment* la base exécute une étape (pas ajouter autour) demande un ancrage mid-flow, ou relève du tier (c) — rare chez Holoon (il *ajoute*, il ne récrit pas le milieu).
- **Extend seul** — pas de mode replace ; le tier (c) reste l'échappatoire.

## Surface d'impact

### Skills
- Chaque skill de base concernée gagne : une **clause d'aiguillage** + des **ancrages nommés**.

### Documentation
- `ADAPTING.md` § « Personnaliser une commande du plugin » — étendre : comment écrire un overlay, la syntaxe d'ancrage.
- Éventuellement `plugin/templates/*/docs/workflow.md.tpl` si le mécanisme touche la doctrine générée.

### Outillage
- Format d'overlay + syntaxe d'ancrage = **nouvelle convention** à documenter ; un check de lint (correspondance ancrages base ↔ overlay) est envisageable (Q4).

### Code
- Aucun code applicatif — ce sont des skills (prompts) + une convention de fichiers.

## Lots d'implémentation

### Lot 1 — Prototype sur `new-adr` (dé-risquer la forme, comparer les deux granularités)
- Prototyper **les deux granularités pour les comparer** : **un hook `after`** (une étape projet ajoutée en fin de `new-adr`) **et un ancrage mid-flow** (les zones d'exploration de la phase 2), + la clause d'aiguillage.
- Implémenter sur `plugin/skills/new-adr/SKILL.md` + un overlay d'exemple simulant Holoon.
- **Mesurer la fiabilité de chacun** sur plusieurs essais : le hook `after` (prepend/append) *vs* l'ancrage mid-flow (splice) — la base « bave »-t-elle ? Hypothèse : le hook est nettement plus robuste.
- **Critère de sortie** : `new-adr` applique proprement hook + ancrage de façon reproductible ; **verdict comparatif fiabilité/ergonomie** ; granularité de fichier (Q1) + syntaxe **arrêtées**.

### Lot 2 — Généraliser aux extensions nettes
- Porter la forme validée sur `capture-lessons`, `changelog-capture`, `dashboard`, `whats-left` (→ `review-backlog`).
- **Critère de sortie** : les 5 skills portent ancrages + aiguillage ; un overlay projet les spécialise **sans fork**.

### Lot 3 — `changelog-draft` (l'hybride)
- Cas le plus lourd (locales, `metadata.json`, captures). Trancher : l'overlay suffit-il, ou reste-t-il en tier (c) ?
- **Critère de sortie** : verdict tranché + implémenté (overlay, ou override documenté comme exception assumée).

### Lot 4 (hors scope 0007, gated future) — Localisation
- Les skills de base sont en anglais, Holoon veut du français. **Axe distinct**, hors périmètre de l'ADR 0007 — noté ici pour mémoire.
- **Déclencheur de réveil** : une fois le mécanisme extend en place, si la langue reste le dernier blocage à l'adoption Holoon → candidat à un futur ADR (skills localisés).

## Alternatives considérées (plus détaillé que l'ADR)

### α — Mode replace dans l'overlay
Écarté : 0/6 des commandes Holoon le réclament (même `changelog-draft` est une spécialisation, pas un remplacement). Le tier (c) — commande locale namespace-distinct — couvre déjà le cas rare de remplacement, sans complexifier le mécanisme extend.

### β — Figer la syntaxe d'ancrage dans l'ADR
Écarté : la fiabilité du dispatch mou et l'ergonomie de la syntaxe ne se connaissent qu'en essayant. Prototype d'abord (Lot 1), design gelé ensuite.

## Questions ouvertes

- ~~**Q1 — Chemin/granularité de l'overlay**~~ **Résolue (2026-07-08) : un fichier par commande, à `.claude/armature/<nom>.md`** (sections `## before` / `## after` / `## <ancrage>`), committé. Sous `.claude/` (config Claude Code), namespacé par le plugin → pattern réutilisable `.claude/<plugin>/<commande>.md`. **NB : surtout pas `.claude/hooks/`** — réservé aux vrais hooks Claude Code (`settings.json`), concept distinct de nos sections d'injection prompt-level.
- **Q2 — Déclaration des points d'injection** *(proposition de tête, à valider au Lot 1)* : **une seule syntaxe — des sections markdown dans l'overlay, le nom de la section décide de la nature.** `before`/`after` = **noms réservés à position implicite** (hooks universels, zéro déclaration côté base). Tout autre `## <id>` = un **ancrage mid-flow** que la base a déclaré inline (`[ancrage projet : <id>]`). Section qui ne matche ni un nom réservé ni un ancrage déclaré → **ignorée** (à flagger, cf. Q4). Élégance : `before`/`after` sont des ancrages à nom réservé + position implicite → un seul mécanisme.
- **Q3 — Fiabilité du dispatch mou** : à quel point la base « bave »-t-elle dans l'injection ? — **le Lot 1 tranche**.
- **Q4 — Lint** : faut-il un check qui valide que les ancrages ciblés par un overlay existent bien dans la base (éviter les overlays silencieusement ignorés) ?

## Progression

| Lot | SHA | Date | Notes |
|---|---|---|---|
| — | — | — | *(rien livré ; ADR + plan ouverts le 2026-07-08)* |

## Follow-ups surfacés pendant l'implémentation

*(vide à l'ouverture)*

## Journal de décisions

- **2026-07-08** — Ouverture. Trois choix de cadrage validés par l'utilisateur : **direction seule** dans l'ADR (design au plan) ; **localisation hors scope** (Lot 4 gated) ; **extend seul** (pas de mode replace). Fondé sur le diagnostic des 6 commandes Holoon (5 extensions + 1 hybride, 0 remplacement).
- **2026-07-08** — **Q1 résolue** (un fichier par commande, `.claude/armature/<nom>.md`, committé) et **Q2 proposée** (sections markdown ; `before`/`after` réservés à position implicite + ancrages nommés déclarés par la base ; un seul mécanisme). Piège de vocabulaire acté : nos « hooks » ≠ les hooks Claude Code de `settings.json` → stockage sous `armature/`, pas `hooks/`.
- **2026-07-08** — **Modèle « hooks + ancrages » retenu comme direction de design** (idée utilisateur, affine le « points d'ancrage nommés » de l'ADR sans le contredire). Points d'injection à deux granularités : **hooks lifecycle** (`before`/`after`/`end`) universels et *plus fiables* (prepend/append > splice) comme forme **dominante**, + **ancrages nommés mid-flow** pour les trous sémantiques précis. Motivé par le diagnostic : la majorité des extensions Holoon (`changelog-draft`, `dashboard`) sont des étapes *après* le cœur = hooks `after` propres ; le mid-flow est la minorité. Le Lot 1 prototype **les deux** pour comparer fiabilité et ergonomie.

## Prochaines actions

- [ ] Lot 1 — prototype sur `new-adr` : forme d'overlay + ancrages + aiguillage, mesure de fiabilité.
- [ ] Décider Q1/Q2 au vu du prototype.
- [ ] Lot 2 — généraliser une fois la forme arrêtée.
- [ ] Lot 3 — trancher `changelog-draft`.
- [ ] Lot 4 — *gated future*, ne rien faire avant le déclencheur (langue = dernier blocage).

---

## À la clôture du plan

Voir [`docs/workflow.md`](../../plugin/templates/fr/docs/workflow.md.tpl) § *Clôturer un plan*. Le Lot 4 étant *gated future* (hors scope 0007), le plan peut passer `implemented` une fois les Lots 1-3 livrés.
