---
status: in-progress
created: YYYY-MM-DD
settled:
related-adr: NNNN
---

# Plan — <titre> (compagnon de l'ADR NNNN)

Compagnon de [l'ADR NNNN](../adr/NNNN-<slug>.md). Capture *comment* c'est implémenté, *quelles* alternatives ont été explorées, et *ce qui* reste ouvert.

> **Pour la grammaire des sections** voir [`docs/workflow.md`](../workflow.md) — chaque section a une vocation précise. Quand un point émerge en cours d'implémentation, se demander : « ça ressemble à quelle section ? »

## Reformulation du problème

Reformuler le problème dans le vocabulaire du code (fichiers concrets, contraintes, entités). Ancre le plan dans le réel — pas un copier-coller du Contexte de l'ADR.

## Forme cible

À quoi ressemble la cible. Schéma, esquisse de modèle de domaine, schéma d'URL, etc. Peut citer des extraits de code ou du pseudo-code.

## Surface d'impact

### Backend
### Frontend
### Données & migrations
### Documentation

Inventaire des couches touchées. Important pour scoper les Lots et estimer l'effort.

## Lots d'implémentation

Découpage en Lots indépendants quand possible. Chaque Lot a un **critère de sortie** mesurable.

### Lot 1 — <titre>
- Puce 1
- Puce 2
- **Critère de sortie** : *…ce qui rend ce Lot terminé…*

### Lot 2 — <titre>
- …

### Lot N (optionnel, gated future) — <titre>
- Déclencheur de réveil documenté si applicable.

## Alternatives considérées (plus détaillé que l'ADR)

Options écartées **par doctrine** (« on a décidé que non »), avec le pourquoi. Plus détaillé que la section *Alternatives* de l'ADR.

### α — Nom de l'option
Pourquoi écartée.

### β — Nom de l'option
Pourquoi écartée.

## Questions ouvertes

Questions ouvertes au moment de l'ouverture du plan. Rayer en `~~résolue~~` au fil de l'implémentation, avec une ligne expliquant la résolution.

- **Q1 — <énoncé>** : *…contexte / piste…*
- **Q2 — <énoncé>** : *…*

## Progression

Table ou liste qui acte ce qui a été livré. Mentionner SHA / PR / date pour chaque Lot.

| Lot | SHA | Date | Notes |
|---|---|---|---|
| Lot 1 — … | `abc1234` | YYYY-MM-DD | … |

## Follow-ups surfacés pendant l'implémentation

Points adjacents découverts en cours d'implémentation. Trois issues possibles (voir [`workflow.md`](../workflow.md) § *Pendant l'implémentation*) :
- traité dans un Lot N+1 de **ce** plan,
- migré en **item de backlog** dédié (créer le fichier, le référencer ici),
- abouti à une **nouvelle ADR** (référencer dans le `related-adrs` de l'ADR parente + ici).

À la clôture du plan, chaque follow-up survivant **doit avoir une destination explicite**.

- **<follow-up 1>** — *…description / destination…*

## Journal de décisions

Trace datée des décisions prises pendant le chantier. Utile pour reconstituer « pourquoi tel choix à tel moment » des mois plus tard.

- **YYYY-MM-DD** — *décision X prise pour la raison Y.*

## Prochaines actions

Checklist pour les actions immédiates ou inter-Lots. Cochées au fil de l'eau. À la clôture, toutes doivent être ✅ ou explicitement pointées vers une destination (Lot, backlog, autre ADR).

- [ ] *action immédiate…*
- [ ] *décision à prendre au Lot N…*

---

## À la clôture du plan

Voir [`docs/workflow.md`](../workflow.md) § *Clôturer un plan : mini-checklist*. En bref :

1. Tous les Lots livrés (ou *gated future* explicite) ✓
2. Toutes les questions ouvertes résolues ou migrées ✓
3. Follow-ups survivants migrés en backlog ✓
4. Frontmatter `status: implemented` + `settled: YYYY-MM-DD` ✓
5. Renommage `YYYY-MM-DD-<slug>.md` + liens entrants mis à jour ✓
6. Entrée de `docs/plans/README.md` mise à jour ✓
7. Leçons capturées dans `lessons-*` ✓
