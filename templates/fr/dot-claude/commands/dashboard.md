---
description: Régénère docs/dashboard.html — vue architecturale par tracks de l'ADR ↔ plan ↔ backlog. Pour la liste tactique priorisée, utiliser /whats-left.
---

# Dashboard

Régénère `docs/dashboard.html`, qui présente l'état actuel ADR ↔ plans ↔ backlog sous forme de **tracks** : une ligne par ADR, avec son plan compagnon et les items de backlog qui la mentionnent.

## Frontière avec `/whats-left`

Les deux commandes peuvent sembler proches — elles parsent les mêmes sources. La frontière fonctionnelle :

| `/dashboard` | `/whats-left` |
|---|---|
| Vue **architecturale** : *« comment le système est-il structuré ? »* | Vue **tactique** : *« qu'est-ce que je fais maintenant ? »* |
| HTML persistant à garder ouvert dans un onglet | Markdown éphémère dans la conversation |
| Tracks ADR + leur backlog lié + bundles candidats ADR | Liste priorisée d'items isolés, items chauds, trous fonctionnels |
| **Inclut** : tracks ADR avec backlog lié, bundles PRINCIPAUX orphelins (candidats ADR), référence (clos) | **Inclut** : items isolés actifs, sous-items orphelins, suggestion de prochain pas |
| **Exclut** : items isolés sans ADR, sous-items orphelins (délégués à `/whats-left`) | **Exclut** : la mécanique ADR ↔ plan elle-même |

Concrètement : un item de backlog actif sans ADR à son nom et ne faisant pas partie d'un bundle PRINCIPAL apparaît dans `/whats-left` mais **pas** dans le dashboard. Inversement, la structure relationnelle ADR ↔ plan est invisible dans `/whats-left` mais centrale dans le dashboard.

## Étapes

1. **Exécuter** :

   ```bash
   python3 tools/generate-dashboard.py
   ```

   Le script est idempotent : il parse `docs/{adr,plans,backlog}/`, détecte les liens entre éléments via les frontmatters + les mentions textuelles `ADR NNNN`, et écrit `docs/dashboard.html`. Aucun effet de bord au-delà de cette écriture.

2. **Afficher la sortie du script** à l'utilisateur (stats : nombre de tracks, backlog liés, orphelins, en référence).

3. **Vérifier le HTML** :
   ```bash
   wc -l docs/dashboard.html
   grep -c 'class="track"' docs/dashboard.html
   ```

4. **Proposer un commit** pour le fichier régénéré — commit direct si ce projet traite la régénération doc-only comme triviale (vérifier `docs/prefs/<login>.md` ou demander), sinon une PR normale :
   ```bash
   git add docs/dashboard.html
   git commit -m "docs(dashboard): régénérer la vue d'ensemble"
   ```

## Quand exécuter ce skill

- Après une session qui a touché plusieurs ADR, plans ou items de backlog (le dashboard dérive sinon).
- Quand l'utilisateur demande de « régénérer le dashboard », « rafraîchir la vue d'ensemble », ou similaire.
- En fin de gros ménage documentaire.

Le dashboard est **statique** — pas de régénération automatique. Ce skill est le moyen explicite de le maintenir à jour.

## Script

`tools/generate-dashboard.py` est versionné. Si tu observes un comportement inattendu (faux positif sur un lien ADR, item mal classé, etc.) :

1. Lis le code source pour identifier la fonction concernée (`find_adr_refs`, `is_resolved`, `is_primary`, `find_subitem_of`).
2. Propose un fix dans le script lui-même + un test mental sur les cas observés.
3. Vérifie que le HTML régénéré confirme le fix.

Patterns connus :
- Les noms de fichiers de plans préfixés par une date (`YYYY-MM-DD-slug.md`) ne doivent **pas** être interprétés comme des ADR — la regex filtre déjà par numéros zero-padded restreints à l'ensemble des ADR *existantes* construit au démarrage du script.
- Les mentions textuelles littérales d'une ADR (« ADR 0011 ») sont prises au pied de la lettre — si un item de backlog dit « candidat à devenir ADR 0011 », il sera lié à 0011 même si cette intention est obsolète. Le fix dans ce cas est côté backlog (corriger le numéro candidat), pas côté script.
