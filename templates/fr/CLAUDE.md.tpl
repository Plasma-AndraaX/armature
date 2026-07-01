# CLAUDE.md

Ce fichier donne à Claude Code (claude.ai/code) le contexte nécessaire pour travailler dans ce dépôt.

## Vue d'ensemble du projet

{{PROJECT_NAME}} — {{PROJECT_ONE_LINER}}

**Stack** : {{PRIMARY_STACK}}

## Documentation

Ce fichier est volontairement court et stable. Le contexte approfondi vit sous [`docs/`](docs/) — à consulter **avant** de se lancer.

| Question | Lire |
|---|---|
| Comment le système fonctionne-t-il aujourd'hui ? | [`docs/architecture.md`](docs/architecture.md) |
| Comment installer / builder / lancer / déployer ? | [`docs/operations.md`](docs/operations.md) |
| Pourquoi ce point n'est-il pas évident ? / quel piège a déjà été rencontré ? | [`docs/lessons-technical.md`](docs/lessons-technical.md) |
| Qu'est-ce qui reste à faire — backlog, sujets différés ? | [`docs/backlog/`](docs/backlog/README.md) |
| Où noter une décision / préférence / leçon pour qu'elle survive à cette conversation ? | [`docs/persistence-strategy.md`](docs/persistence-strategy.md) — matrice « type d'info → fichier ». |
<!-- FULL-ONLY --> | Pourquoi ce choix architectural a-t-il été fait ? | [`docs/adr/`](docs/adr/README.md) (ADR numérotées) |
| Comment *X* a-t-il été implémenté / quelles alternatives ont été pesées ? | [`docs/plans/`](docs/plans/README.md) (compagnons des ADR) |
| Quand ouvrir un ADR plutôt qu'un item de backlog ? / où vont les points qui émergent en cours d'implémentation ? | [`docs/workflow.md`](docs/workflow.md) — cycle de vie ADR ↔ plan ↔ backlog. | <!-- /FULL-ONLY -->

Quand tu résous un problème non-évident ou rencontres un piège absent du code, ajoute une section datée à `docs/lessons-technical.md` (ou `docs/lessons-domain.md` si ce projet en a un). <!-- FULL-ONLY -->Quand tu fais un choix architectural, rédige un nouvel ADR (voir [`docs/adr/template.md`](docs/adr/template.md)). <!-- /FULL-ONLY -->Pour le reste — voir [`docs/persistence-strategy.md`](docs/persistence-strategy.md) pour la matrice complète<!-- FULL-ONLY -->, et [`docs/workflow.md`](docs/workflow.md) pour le *quand*<!-- /FULL-ONLY -->.

## Explorer le code

Si une recherche limitée au repo ne donne rien, **élargis le motif, jamais le périmètre**. Essaie un autre nom de fichier probable, grep sur le nom du type/module. Évite les recherches sur tout le filesystem hors du projet — elles sont lentes, et tout ce que le build référence est par construction dans ce repo.

## Build & Commandes de développement

<!-- À remplir une fois operations.md rédigé — garder cette section courte, pointer vers operations.md pour le détail. -->

```bash
# TODO : renseigner les vraies commandes pour {{PRIMARY_STACK}}
```

## Architecture

<!-- Pointeur court vers architecture.md ; ne pas dupliquer son contenu ici. -->

Voir [`docs/architecture.md`](docs/architecture.md) pour la forme actuelle du système.

## Style de code

<!-- À remplir une fois les conventions du projet stabilisées (indentation, nommage, linting). -->
