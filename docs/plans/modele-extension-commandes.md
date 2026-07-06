---
status: in-progress
created: 2026-07-06
settled:
related-adr: 0006
---

# Plan — Modèle d'extensibilité des commandes (compagnon de l'ADR 0006)

Compagnon de [l'ADR 0006](../adr/0006-modele-extension-commandes.md). Capture *comment* le modèle se réalise dans le kit, *quelles* alternatives ont été explorées, et *ce qui* reste ouvert (surtout : le tier (b), gelé).

> **Pour la grammaire des sections** voir [`docs/workflow.md`](../../plugin/templates/fr/docs/workflow.md.tpl) — chaque section a une vocation précise.

## Reformulation du problème

Les commandes vivent maintenant sous `plugin/skills/<nom>/SKILL.md`, lues depuis `${CLAUDE_PLUGIN_ROOT}`, invoquées `/armature:<nom>`. Un projet consommateur ne peut pas éditer ces fichiers (partagés) sans changer le comportement pour tous. La question : où atterrit chacune des **quatre natures** de personnalisation observées sur Holoon ?

1. **Conventions transverses** — « pas de `Co-Authored-By` », Gitflow, `deciders` par défaut. Reviennent dans plusieurs commandes.
2. **Données de config** — glossaire i18n, liste des locales. De la donnée, pas des instructions à fusionner.
3. **Comportement additif léger** — cibles/exemples de stack ajoutés à une commande générique.
4. **Comportement franchement différent** — le `changelog-draft` maison (181 l. vs 31 l.).

## Forme cible

Le mapping des quatre natures sur des mécanismes **déjà présents** dans le kit :

| Nature | Mécanisme | État |
|---|---|---|
| (1) Conventions transverses **équipe** | `CLAUDE.md` du projet (auto-chargé) | **Existe** |
| (1) Conventions transverses **perso** | `docs/prefs/<login>.md` (auto-chargé, consulté par `new-adr` / `document-standards` / `dashboard`) | **Existe** |
| (2) Données de config | fichier de données du projet (p. ex. `metadata.json`, glossaire) lu par une commande override | **Existe** (relève de (c)) |
| (3) Additif léger | overlay à points d'ancrage `.claude/armature/<nom>.md` | **Gelé** (tier b, pas de déclencheur) |
| (4) Comportement différent | commande locale `.claude/commands/<nom>.md`, namespace `/<nom>` distinct de `/armature:<nom>` | **Existe** (tier c) |

Fait structurant : `CLAUDE.md` **et** `docs/prefs/<login>.md` sont **auto-chargés à chaque session** → toute skill de base tournant dans le projet « voit » déjà ces conventions sans mécanisme de lecture dédié. Le tier (a) est donc une **observation**, pas une construction.

## Surface d'impact

### Documentation
- `docs/adr/0006-*` + ce plan + les deux index (livré dans le commit d'ouverture).
- `docs/backlog/command-extension-mechanism.md` → reclassé « sujet clos, voir ADR 0006 » ; `docs/backlog/README.md` → item déplacé en section « référence / clos ».
- **`ADAPTING.md`** — ajouter un court paragraphe qui *bénit* l'override (c) : quand forker une commande en local est le bon choix (comportement franchement différent), et pourquoi le namespace distinct rend la coexistence propre. Point d'entrée doc pour un tiers.

### Skills (résidu du tier a — optionnel, incrémental)
- Les skills qui produisent plus que des commits (`new-adr` surtout) pourraient gagner une ligne « avant d'appliquer les valeurs par défaut, défère aux conventions du projet (`CLAUDE.md`, `docs/prefs/<login>.md`) » — au-delà du seul message de commit déjà couvert. **Non prérequis** : les fichiers étant auto-chargés, le modèle les prend déjà en compte en pratique.

### Code
- Aucun. Le tier (b) est gelé ; les tiers (a) et (c) ne demandent pas de machinerie.

## Lots d'implémentation

### Lot 1 — Geler la décision (docs)
- ADR 0006 `accepted` + ce plan + index ADR/plans + reclassement backlog + `CLAUDE.md` § « Where things stand » + `CHANGELOG.md` [Unreleased].
- **Critère de sortie** : ADR 0006 committée, backlog pointant dessus, lint vert.

### Lot 2 — Bénir l'override (c) dans `ADAPTING.md`
- Un paragraphe : quand préférer une commande locale, coexistence par namespace, dette assumée (pas de mise à jour auto).
- **Critère de sortie** : `ADAPTING.md` décrit le tier (c) comme un choix légitime, pas un pis-aller.

### Lot 3 (optionnel, incrémental) — Généraliser « défère aux conventions du projet »
- Étendre l'instruction au-delà du message de commit dans `new-adr` (et toute skill où ça paie).
- **Critère de sortie** : au moins `new-adr` invite explicitement à consulter `CLAUDE.md` + `docs/prefs` pour ses valeurs par défaut. **Ne pas forcer** si l'auto-chargement suffit en pratique.

### Lot 4 (gated future) — Overlay à points d'ancrage (tier b)
- **Déclencheur de réveil** : une personnalisation *additive légère* devient récurrente sur ≥ 2 projets et pénible à maintenir à la main (override trop lourd pour le besoin).
- Forme pressentie : une section d'ancrage nommée dans la skill de base (p. ex. « cibles/exemples projet ») + instruction « si `.claude/armature/<nom>.md` existe, lis sa section `<targets>` et intègre-la ici ». L'insertion reste **prévisible** (ancrage nommé), pas improvisée par le modèle à chaque run.
- **Critère de sortie** : *n/a tant que le déclencheur n'a pas sonné.*

## Alternatives considérées (plus détaillé que l'ADR)

### α — Fichier d'extension unique `.claude/armature/<nom>.md` pour tout
Traiterait les quatre natures pareil. Duplique les conventions transverses (un fichier par commande les répète alors qu'elles doivent vivre à un seul endroit), transforme de la donnée (glossaire) en instructions à fusionner, et pour le cas lourd l'overlay serait aussi gros que la commande. Écarté : un overlay « universel » redevient le fork qu'on fuit.

### β — Construire le tier (b) maintenant
Techniquement faisable et léger. Écarté *pour l'instant* : aucun besoin additif *récurrent* — Holoon est intégralement couvert par override (c). Bâtir un mécanisme pour un cas hypothétique contredit la doctrine du repo (cf. `contribution-and-extension-model.md`, exemple canonique du report assumé).

### γ — Interdire l'override et tout absorber dans le plugin
Écarté : nierait la nature (4). Un autre workflow n'est pas un enrichissement de la base.

## Questions ouvertes

- ~~**Q1 — Faut-il vraiment le Lot 3 ?**~~ **Résolue (2026-07-06) : non.** `new-adr` consulte déjà `docs/prefs` pour le commit ; `CLAUDE.md` + `docs/prefs` étant auto-chargés, le modèle voit déjà les conventions du projet en rédigeant l'ADR. Éditer une skill *partagée* pour ce nudge la bloaterait sans gain démontré → **Lot 3 non retenu**.
- **Q2 — Un tiers découvrira-t-il le tier (c) sans le Lot 2 ?** : c'est justement l'objet du Lot 2 (le rendre explicite dans `ADAPTING.md`).

## Progression

| Lot | SHA | Date | Notes |
|---|---|---|---|
| Lot 1 — geler la décision | `bb9b3d5` | 2026-07-06 | commit d'ouverture ADR+plan+index+backlog |
| Lot 2 — bénir l'override (c) | `—` | 2026-07-06 | section « Personnaliser une commande du plugin » dans `ADAPTING.md` |
| Lot 3 — généraliser « défère aux conventions » | *non retenu* | 2026-07-06 | cosmétique (auto-chargement suffit) — voir Q1 |

## Follow-ups surfacés pendant l'implémentation

*(vide à l'ouverture)*

## Journal de décisions

- **2026-07-06** — Choix de **geler le modèle en ADR** plutôt que de laisser la réflexion ouverte : la trouvaille « le tier (a) est déjà porté par `CLAUDE.md` + `docs/prefs`, auto-chargés » **tranche** la question qui était ouverte (« faut-il un nouveau mécanisme ? » → non). La décision fige aussi un « non » (pas d'overlay tier b) à la manière de l'ADR 0005.
- **2026-07-06** — **Lot 3 non retenu.** Même logique anti-bloat que l'ADR : une skill partagée ne gagne pas à être alourdie pour un nudge que l'auto-chargement rend déjà effectif. La liberté d'ajouter « défère aux conventions du projet » reste ouverte pour le jour où une skill le *démontre*.

## Prochaines actions

- [x] Lot 1 — ADR 0006 + plan + index + reclassement backlog + CLAUDE.md + CHANGELOG.
- [x] Lot 2 — section « Personnaliser une commande du plugin » dans `ADAPTING.md`.
- [x] Lot 3 (optionnel) — **évalué, non retenu** (auto-chargement suffit ; cf. Q1 / journal).
- [ ] Lot 4 — *gated future*, ne rien faire avant le déclencheur (customisation additive légère récurrente).

---

## À la clôture du plan

Voir [`docs/workflow.md`](../../plugin/templates/fr/docs/workflow.md.tpl) § *Clôturer un plan*. Le Lot 4 étant *gated future*, le plan peut passer `implemented` une fois les Lots 1–2 livrés (Lot 3 optionnel, Lot 4 explicitement reporté).
