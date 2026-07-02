# Architecture Decision Records — claude-project-kit

Index des ADR **du kit lui-même**, les plus récentes en premier. Chaque ADR est un enregistrement court, gelé (une fois `accepted`) d'une décision structurante unique — le *quoi* et le *pourquoi*. Le *comment* vit dans le plan compagnon sous [`../plans/`](../plans/README.md).

> **Pourquoi le kit a-t-il maintenant son propre `docs/adr/` ?** Jusqu'à la 0.2.0, le kit documentait ses décisions dans `README.md`/`ADAPTING.md` et gardait le format ADR pour les *projets bootstrapés* uniquement — `docs/backlog/README.md` notait que certains items du backlog en étaient « candidats ». Les deux premières ADR ci-dessous (modules test + incidents) sont les premières décisions du kit assez structurantes pour mériter le trajet lourd. Le kit **dogfoode** ainsi sa propre machinerie ADR ↔ plan.

**Format** : le kit utilise exactement le gabarit qu'il génère dans les projets — voir [`../../templates/fr/docs/adr/template.md`](../../templates/fr/docs/adr/template.md) (et [`../../templates/fr/docs/workflow.md.tpl`](../../templates/fr/docs/workflow.md.tpl) pour savoir quand ouvrir une ADR plutôt qu'un item de backlog).

| # | Titre | Statut | Date | Plan compagnon |
|---|---|---|---|---|
| [0003](0003-commande-coding-standards.md) | Commande `/coding-standards` (conventions via source vivante) | accepted | 2026-07-02 | [plan](../plans/commande-coding-standards.md) |
| [0002](0002-journal-incidents.md) | Journal d'incidents / postmortem (module `docs/incidents/`) | accepted | 2026-07-02 | [plan](../plans/2026-07-02-journal-incidents.md) |
| [0001](0001-strategie-de-test.md) | Stratégie de test des projets bootstrapés (module `docs/testing.md`) | accepted | 2026-07-02 | [plan](../plans/2026-07-02-strategie-de-test.md) |
