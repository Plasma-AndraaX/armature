# Documentation

Carte de la documentation du projet. Chaque document a une vocation distincte ; ils ne se recouvrent pas.

| Document | Vocation | Nature |
|---|---|---|
| [`architecture.md`](architecture.md) | Comment le système fonctionne *aujourd'hui* | Vivant — mis à jour au fil de l'évolution du système |
| [`operations.md`](operations.md) | Setup, build, run, debug, déploiement | Vivant — mis à jour au fil de l'évolution de l'outillage |
| [`lessons-technical.md`](lessons-technical.md) | Pièges et patterns techniques non dérivables du code | Append-only — une entrée par leçon, datée |
| [`coding-standards.md`](coding-standards.md) | Conventions de style/nommage réellement en vigueur, par langage/module si hétérogène | Vivant — mis à jour au fil de l'adoption des conventions |
<!-- FULL-ONLY --> | [`adr/`](adr/README.md) | Architecture Decision Records — numérotées, courtes, une décision par fichier | Chaque ADR est stable une fois `accepted` ; les nouvelles ADR supersèdent les anciennes |
| [`plans/`](plans/README.md) | Plans d'implémentation/investigation détaillés, rattachés aux ADR | Évoluent tant qu'`in-progress`, gelés avec préfixe de date une fois `implemented` ou `rejected` | <!-- /FULL-ONLY -->
| [`backlog/`](backlog/README.md) | Idées / dette / sujets différés pas encore mûrs pour une ADR | Un fichier par thème, ou groupé<!-- FULL-ONLY --> — voir `workflow.md` pour les patterns de granularité<!-- /FULL-ONLY --> |
<!-- FULL-ONLY --> | [`testing.md`](testing.md) | Stratégie de test : niveaux, philosophie, ce qu'on ne teste pas | Vivant |
| [`incidents/`](incidents/README.md) | Postmortems d'incidents à impact réel | Un fichier par incident, daté |
| `lessons-domain.md` *(si domaine métier riche)* | Règles métier et invariants de domaine | Append-only |
| [`prefs/`](prefs/README.md) | Préférences personnelles par contributeur, committées | Un fichier par contributeur |
| [`claude-code-tooling.md`](claude-code-tooling.md) | Inventaire des plugins/skills/hooks Claude Code utilisés sur ce projet | Vivant | <!-- /FULL-ONLY -->
<!-- CHANGELOG-ONLY --> | [`changelog/`](changelog/README.md) | Notes de release utilisateur — capturées au fil de l'eau, rédigées à la release | `_next.md` est un brouillon courant, vidé à chaque release | <!-- /CHANGELOG-ONLY -->

## Conventions de rédaction

- **Leçons** : chaque titre de section est la leçon elle-même, sous forme actionnable (ex. *« Ne pas faire X quand Y »*, pas juste *« X »*). Date en fin de section.
<!-- FULL-ONLY --> - **ADR** : utiliser le gabarit [`adr/template.md`](adr/template.md). Les garder courtes — le détail va dans le plan compagnon. <!-- /FULL-ONLY -->
<!-- FULL-ONLY --> - **Plans** : nom de fichier en slug tant qu'`in-progress` (peut évoluer). Renommé avec préfixe `YYYY-MM-DD-` une fois réglé (implemented ou rejected) — devient un record archéologique. <!-- /FULL-ONLY -->
- **Architecture/Operations** : décrire le *quoi* et le *comment*. Pour le *pourquoi*, référencer `lessons-*.md`<!-- FULL-ONLY --> ou une ADR précise<!-- /FULL-ONLY -->.

<!-- FULL-ONLY -->
## Références croisées

- Les ADR citent leurs plans liés dans leur frontmatter (`related-plans`).
- Les plans citent leur ADR parente dans leur frontmatter (`related-adr`).
- `architecture.md` peut citer des leçons et des ADR en ligne quand une décision façonne un mécanisme.
<!-- /FULL-ONLY -->
