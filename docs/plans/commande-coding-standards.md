---
status: in-progress
created: 2026-07-02
settled:
related-adr: 0003
---

# Plan — Commande `/coding-standards` (compagnon de l'ADR 0003)

Compagnon de [l'ADR 0003](../adr/0003-commande-coding-standards.md). Capture *comment* la commande est implémentée, et *ce qui* reste ouvert.

## Reformulation du problème

Ajouter un skill `coding-standards.md` généré dans `.claude/commands/` des projets (les deux profils), qui produit/actualise `docs/coding-standards.md` pour la stack, en s'appuyant sur `find-docs`/`ctx7` quand présent. Contraintes : rester documentaire (pas de scaffold), honnête sur le statut « proposé », robuste sans `ctx7` (fallback signalé), et multi-langage (une section par langage/écosystème).

## Forme cible

Skill en phases (même style que `new-adr.md`) :

1. **Déterminer la stack** — depuis `$ARGUMENTS`, sinon la section Stack de `CLAUDE.md`, sinon détection légère (manifestes). Si multi-langage, traiter chaque écosystème séparément.
2. **Récupérer les conventions idiomatiques** — par langage, viser **deux sources** : le **formatter** (formatage : indentation, quotes, semis, largeur, virgules) et le **style-guide/linter** (nommage, structure, imports). Via `find-docs`/`ctx7` si disponible (`library` puis `docs`) ; **sinon**, dégrader vers la connaissance du modèle des conventions *largement adoptées*, en le signalant explicitement dans le doc généré.
3. **Synthétiser dans `docs/coding-standards.md`** — remplir le squelette existant (Vue d'ensemble / Conventions par langage / Application) ; pivot sur l'outillage recommandé + les conventions clés que l'outil ne fixe pas ; **statut en tête** : *« proposé le YYYY-MM-DD selon la stack, à confirmer »*. Ne pas inventer de règles exotiques — viser l'idiomatique. Sur un projet avec conventions déjà observées, **compléter/actualiser** sans écraser sans confirmation.
4. **Offrir un `.editorconfig` de base** — proposer (pas d'office) un `.editorconfig` déclaratif (indentation, charset, EOL, trim trailing whitespace) dérivé des conventions retenues. Accepter/refuser au choix.
5. **Présenter avant d'écrire** — montrer le diff proposé de `coding-standards.md` (+ `.editorconfig` le cas échéant) ; n'écrire qu'après confirmation.

Périmètre : **jamais** installer un outil, générer un `.prettierrc`/`.eslintrc`, ni coder en dur une règle d'équipe non demandée.

## Surface d'impact

### Commande (bilingue)
- **Nouveaux** : `templates/{en,fr}/dot-claude/commands/coding-standards.md`.

### Skill bootstrap
- `.claude/commands/bootstrap-claude-env.md` : Phase 4, ajouter `coding-standards.md` à la liste des commandes générées **en Minimal** (donc dans les deux profils, avec `propose-kit-improvement`/`pull-kit-updates`). Mentionner qu'après un bootstrap de projet neuf, lancer `/coding-standards` est un next step naturel (Phase 6 summary).

### Intégrations légères
- `templates/{en,fr}/docs/coding-standards.md.tpl` : note en tête « pour (re)générer une proposition selon la stack : `/coding-standards` ».
- `templates/{en,fr}/docs/persistence-strategy.md.tpl` : sur la ligne coding-standards, mentionner la commande.
- `templates/{en,fr}/docs/claude-code-tooling.md.tpl` *(Full)* : ajouter `/coding-standards` à la table des skills custom.

### Outillage
- `tools/lint-templates.py` : **rien à ajouter** — `coding-standards.md` n'est pas dans `MINIMAL_SKIP_COMMANDS` (généré dans les deux profils), la parité `en`/`fr` suffit. Vérifier le lint vert.

## Lots d'implémentation

### Lot 1 — Commande + intégrations
- Écrire la commande (en+fr), brancher bootstrap Phase 4 + les 3 intégrations légères.
- **Critère de sortie** : `lint-templates.py` vert ; la commande rendue en Minimal *et* Full.

### Lot 2 (gated) — Dogfood réel
- Lancer `/coding-standards` pour de vrai sur un projet (le *run manuel end-to-end* de `docs/testing.md`). **Déclencheur** : un prochain projet neuf ou une session dédiée. Non bloquant pour la livraison de la commande.

## Alternatives considérées (plus détaillé que l'ADR)

### α — Sous-commande du bootstrap plutôt qu'un skill autonome
Écartée : cf. ADR. Le couplage au one-shot du bootstrap tue la ré-exécution.

### β — Embarquer un `.editorconfig` figé par stack dans le kit
Écartée : même travers que la table figée. Le `.editorconfig` est *dérivé* des conventions retenues à l'exécution, pas pioché dans une banque statique.

## Questions ouvertes

- ~~**Q1 — profil**~~ : résolu — les deux profils (coding-standards.md ship dans les deux).
- ~~**Q2 — sans `ctx7`**~~ : résolu — fallback vers la connaissance du modèle, signalé dans le doc généré (statut « de mémoire, à vérifier »).
- ~~**Q3 — `.editorconfig`**~~ : résolu — offert, pas d'office ; dérivé, pas figé.

## Journal de décisions

- **2026-07-02** — commande dédiée retenue (ADR 0003), source vivante `find-docs`/`ctx7` avec fallback, périmètre documentaire strict, `.editorconfig` optionnel. Faisabilité `ctx7` validée sur Prettier.

## Prochaines actions

- [ ] Lot 1 — commande (en+fr) + intégrations + lint vert.
- [ ] Lot 2 (gated) — dogfood réel sur un projet, à la prochaine occasion.
