---
description: Lancer une réflexion structurée sur une décision architecturale qui aboutit à une ADR + son plan compagnon.
argument-hint: [sujet ou question à creuser]
---

# Nouvelle décision architecturale

L'utilisateur veut réfléchir à un sujet qui mérite une ADR (*Architecture Decision Record*) : une décision structurante, non-triviale, avec des tradeoffs explicites. Tu structures le processus pour que la décision soit **cuite avant d'écrire**, puis tu produis l'ADR + son plan compagnon selon les conventions de ce dépôt.

Sujet proposé par l'utilisateur : **$ARGUMENTS**

## Quand une ADR se justifie

Une ADR est pertinente si **au moins deux** de ces conditions sont réunies :
- La décision touche plusieurs zones du code (plusieurs modules/couches/features).
- Il y a plus d'une option crédible, avec des tradeoffs qu'il faudra savoir expliquer plus tard.
- Tu veux une trace durable du **pourquoi**, pas juste du **quoi** (ça, c'est le commit).
- La décision est irréversible ou coûteuse à revisiter (migration de schéma, refonte de permissions, changement de modèle).
- La décision casse un invariant documenté dans `lessons-*.md`.

Si le sujet ne coche **aucune** de ces cases, dis-le et propose une alternative plus légère (une simple PR, un commentaire de code, une entrée dans `lessons-*`). **Refuse d'écrire une ADR pour un sujet qui ne le mérite pas** — un marécage d'ADR dilue la valeur de toutes les autres.

## Processus

### Phase 1 — Cadrer le problème

Avant d'écrire quoi que ce soit, seul dans ta tête :

- Reformule le problème dans tes propres mots. Si tu n'y arrives pas, tu ne l'as pas compris — pose des questions.
- Liste les **invariants** et **contraintes** (techniques, métier, delai, stack).
- Identifie **au moins 2 options crédibles**, pas juste « l'évidente ». Si tu n'en trouves qu'une, cherche encore : tu n'as pas une ADR, tu as un TODO.

### Phase 2 — Explorer le terrain

Pour les décisions qui touchent une zone inconnue ou étendue :

- Lance des agents `Explore` **en parallèle** sur les zones touchées. Un sous-sujet par agent.
- Demande des rapports **structurés** avec des références fichier:ligne, pas des dumps de fichiers. Impose une limite de mots (~500).
- Croise les rapports pour mesurer l'impact réel.
- Consulte les `docs/lessons-*.md` et `docs/adr/` existants — ils peuvent déjà détenir une partie de la réponse ou documenter des invariants à respecter.

**Ne commence pas à rédiger tant que tu n'as pas :**
- Une vision claire des zones impactées et du coût estimé.
- Les options crédibles avec leurs coûts respectifs.

### Phase 3 — Aller-retour sur les tradeoffs

Présente les options à l'utilisateur, pour chacune :

- **Ce qu'on gagne** (positifs concrets, pas vagues).
- **Ce qu'on paie** (coûts et risques honnêtes — pas de blanchiment).
- **Ce qui reste ambigu** (questions ouvertes à trancher).

Donne ton avis avec son raisonnement. Un avis neutre « toutes les options se valent » est une démission — construis un point de vue. Mais reste ouvert à être contredit.

**Ne rédige pas l'ADR tant que :**
- Toutes les questions ouvertes bloquantes ne sont pas tranchées.
- L'utilisateur n'a pas validé **explicitement** l'option retenue.
- Le périmètre *dedans* et *dehors* n'est pas clair.

Si la discussion dérive vers un nouveau sujet adjacent, propose une ADR séparée plutôt que de tout empiler.

### Phase 4 — Rédiger l'ADR

Fichier : `docs/adr/NNNN-titre-en-kebab-case.md`, 4 chiffres zero-padded. Regarde `docs/adr/` pour le prochain numéro libre. Suis **`docs/adr/template.md`**.

Frontmatter :
```yaml
---
status: proposed        # passera à accepted quand l'utilisateur valide
date: YYYY-MM-DD
deciders: []
superseded-by:
related-adrs: []
related-plans: [<slug>]
---
```

Sections :
- **Contexte** — le problème en contexte. Ce qui force la décision. Bref (200-400 mots).
- **Décision** — une ou deux phrases, voix active. Ce qu'on choisit.
- **Conséquences** — *Positives* / *Négatives* / *Neutres*. **Sois honnête sur les négatifs.** Une ADR qui ne liste que des avantages est suspecte.
- **Alternatives considérées** — options rejetées avec une raison brève. Le détail va dans le plan.
- **Références** — ADR liées, plan compagnon (chemin), liens externes.

Mets à jour `docs/adr/README.md` avec la nouvelle entrée dans l'index (numéro, titre, statut, date).

### Phase 5 — Rédiger le plan compagnon

Fichier : `docs/plans/<slug>.md` (même slug que l'ADR, sans préfixe de date tant que `in-progress`).

Frontmatter :
```yaml
---
status: in-progress
created: YYYY-MM-DD
settled:
related-adr: NNNN
---
```

Sections recommandées :
- **Reformulation du problème** — le problème dans le vocabulaire du code (classes, services, tables).
- **Forme cible** — schéma cible, modèles, interfaces. Esquisse de code si utile.
- **Surface d'impact** — couches touchées, avec fichier:ligne quand tu les as.
- **Lots d'implémentation** — découpage en PR indépendamment mergeables, dans un ordre qui préserve la cohérence. **Chaque lot a un *critère de sortie* explicite**.
- **Alternatives considérées (plus détaillé que l'ADR)** — raisonnement de rejet détaillé, avec esquisses de code si pertinent.
- **Questions ouvertes** — ce qui reste à trancher avant de démarrer tel ou tel lot.
- **Follow-ups surfacés pendant l'implémentation** — vide au départ, rempli au fil du travail (ex. via `/capture-lessons`).
- **Prochaines actions** — checklist concrète pour démarrer.

Mets à jour `docs/plans/README.md` avec la nouvelle entrée dans l'index.

### Phase 6 — Commiter les docs

Un **seul commit `docs:`** pour l'ADR, le plan, et les deux index. Ne mélange pas avec du code. Vérifie `docs/prefs/<login>.md` (si ce projet l'utilise) pour les conventions de message de commit de l'utilisateur avant d'écrire le commit.

## Règles

- **Numérotation ADR** : 4 chiffres zero-padded, le prochain libre dans `docs/adr/`.
- **ADR immuable une fois `accepted`** : pour revisiter, écrire une nouvelle ADR qui la supersède (`superseded-by` dans le frontmatter de l'ancienne).
- **Plan modifiable tant que `in-progress`** ; gelé au ménage final (renommé avec préfixe `YYYY-MM-DD-` + `status: implemented` ou `rejected`).

## Ce que tu ne fais PAS

- Écrire l'ADR avant que les tradeoffs soient discutés et les questions ouvertes tranchées — tu prendrais la décision à la place de l'utilisateur.
- Masquer les négatifs pour vendre la décision retenue — l'ADR doit rester utilisable en rétrospective hostile, pas seulement pour célébrer.
- Mélanger l'ADR et le plan d'implémentation : l'ADR est le **quoi + pourquoi**, le plan est le **comment**.
- Démarrer l'implémentation dans la foulée — la Phase 6 s'arrête après le commit docs. L'implémentation vient dans des commits séparés, éventuellement découpés selon les lots du plan.
- Écrire une ADR pour une décision triviale ou un refactor évident — overkill, utilise une simple PR.
- Empiler dans l'ADR des sujets adjacents qui méritent leur propre ADR — garde le périmètre serré, propose des ADR séparées pour les sujets connexes.
