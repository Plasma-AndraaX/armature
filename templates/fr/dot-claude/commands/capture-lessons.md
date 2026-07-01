---
description: Passer en revue le travail récent et capturer ce qui mérite d'aller dans lessons-*, architecture, operations, et le plan en cours.
---

# Capture des leçons

Tu es appelé à la fin d'un travail non-trivial pour faire un passage de capture et mise à jour des docs. Tu ne captures pas tout — applique les filtres de pertinence ci-dessous de façon agressive et propose des ajouts concrets, actionnables.

## Cibles courantes (non exhaustives)

Les cibles ci-dessous couvrent la majorité des cas. **Ce n'est pas une liste fermée** : si un autre fichier est le bon endroit (`CLAUDE.md`, un README de sous-dossier, un doc spécifique à une feature, une ADR `accepted` à superseder, voire un nouveau fichier à créer), vas-y. Choisis la cible selon la nature de ce que tu captures ; ne force pas une info dans une case où elle n'appartient pas.

| Fichier | Quand y écrire |
|---|---|
| `docs/lessons-technical.md` | Pièges techniques non-évidents : subtilités de framework/librairie, pièges d'outillage, comportement runtime subtil |
| `docs/lessons-domain.md` *(si ce projet en a un)* | Règles métier, invariants de domaine, sémantiques qu'on ne peut pas deviner du code seul |
| `docs/architecture.md` | Changements qui affectent « comment le système marche aujourd'hui » (nouvelle relation entre composants, nouveau pattern adopté) |
| `docs/operations.md` | Commandes, workflows, prérequis pour setup / build / run / déploiement / migrations |
| `docs/plans/<slug>.md` (in-progress) | Journal de progression (lot livré), follow-ups surfacés pendant l'implémentation, questions ouvertes restantes |
| *autre* | Si le bon endroit n'est pas dans cette table, propose-le à l'utilisateur en le justifiant |

## Critères de pertinence — filtre agressif

### Capture **si et seulement si** :
- **Non-dérivable du code** — aucun contributeur ne pourrait reconstruire cette info en lisant les fichiers. Si la réponse est « grep + 5 min de lecture », passe ton chemin.
- **Non-évident** — un développeur expérimenté ne le devinerait pas du premier coup. Si c'est un idiome courant du langage/framework, passe ton chemin.
- **Actionnable** — la leçon dit quoi faire ou éviter. Une pure description n'aide personne.
- **Stable** — restera vrai pendant au moins 6 mois. Un fix de bug spécifique ne va pas dans les leçons — le message de commit suffit.
- **Coûteux à redécouvrir** — le prochain qui tombe dessus perdra un temps visible (> 30 min) si la leçon n'existe pas.

### Ne capture **jamais** :
- Des solutions à des bugs spécifiques (commit + PR suffisent)
- Des conventions déjà visibles dans le code (nommage, formatage)
- Ce qu'un test couvre déjà
- Des détails volatils (versions de librairies, config d'environnement)
- Une redite d'une leçon existante (mets-la à jour à la place)

## Processus

### 1. Cadrer le périmètre

Relis les derniers commits (`git log -20 --oneline`) et/ou la conversation en cours. Si le périmètre n'est pas clair, demande brièvement à l'utilisateur.

### 2. Lister les candidats

Construis deux colonnes mentales :
- **Passent** : items qui cochent *toutes* les cases de la liste « capture si ».
- **Rejetés** : items proches mais qui ratent un critère — cite-les en 1 ligne pour montrer que tu ne les as pas oubliés.

Objectif : **2 à 4 items à capturer** par passage typique. Si tu en as plus, tu filtres mal — resserre.

### 3. Rédiger selon le format du fichier cible

#### `lessons-technical.md` / `lessons-domain.md` (append-only, ajouter en haut)

```markdown
## [Titre actionnable en une phrase]

[Corps : 2-3 paragraphes. Commence par le contexte/la situation où le piège se manifeste. Enchaîne avec la règle ou le pattern à appliquer. Termine par un exemple concret du dépôt si pertinent.]

_Capturé le YYYY-MM-DD._
```

- **Ne réécris pas les anciennes entrées.**
- Si une ancienne leçon doit être invalidée, ajoute une nouvelle en haut ET marque l'ancienne comme *superseded*, en préservant son corps en citation.

#### `architecture.md` / `operations.md` (éditables directement)

Ces deux fichiers ne sont **pas** append-only. Édite la section précise concernée, évite les réécritures massives. Garde le ton et la structure existants.

#### `docs/plans/<slug>.md` in-progress

- **Journal de progression** : si un lot a été livré, ajoute une ligne dans la section *Progression* avec le SHA du commit de merge.
- **Follow-ups** : tout sujet surfacé qui sort du périmètre du plan actuel → section *Follow-ups surfacés pendant l'implémentation*, daté.

### 4. Proposer avant de commiter

Avant d'éditer, présente à l'utilisateur la liste courte (passés + rejetés) pour validation. Ça évite de capturer du bruit ou d'oublier quelque chose d'important.

### 5. Commit séparé

Tout ce passage tient en **un seul commit `docs:`**. Ne mélange jamais avec du code.

## Avant de proposer chaque item, pose-toi deux questions

- *« Est-ce qu'un nouveau contributeur perdrait vraiment du temps si cette info n'existait pas ? »* — si tu hésites, supprime.
- *« Un LLM pourrait-il deviner cette info en lisant le code du dépôt ? »* — si oui, supprime.

## Ce que tu ne fais PAS

- Capturer « tout ce qui s'est passé dans la conversation » — tu es un filtre, pas un journal.
- Rédiger des leçons descriptives (« voici comment marche X ») au lieu d'actionnables (« quand tu tombes sur X, fais Y »).
- Toucher au code dans ce passage — uniquement les docs.
- Réécrire ou résumer une leçon existante pour la « clarifier » — elle est dans l'historique, laisse-la tranquille ou supersède-la explicitement.
- Capturer quand la session n'a rien produit de non-évident — il est parfaitement acceptable de conclure « rien à capturer ».
