# Workflow — ADR ↔ plan ↔ backlog

**Quand utiliser quoi, et où vont les choses qui émergent en cours de route.**

[`persistence-strategy.md`](persistence-strategy.md) dit *où* mettre les choses. Ce document dit *quand* — la vie d'une décision, de l'idée à la clôture, et comment les sujets adjacents qui surgissent en chemin sont rangés sans se perdre.

## Le cycle

```
              IDÉE / DOULEUR
                    │
                    ▼
           Est-elle prête à
           être tranchée ?
                    │
            ┌───────┴───────┐
           NON             OUI
            │                │
            ▼                ▼
        BACKLOG           ADR (proposed)
       <slug>.md              │
            │        ┌────────┼────────┐
            │        ▼        ▼        ▼
            │    accepted  deferred  rejected
            │        │        │         │
            │        ▼    ┌─ trigger  └─> fin
            │   PLAN      │   de réveil
            │   COMPAGNON
            │  (in-progress)
            │        │
            │        ▼
            │  IMPLÉMENTATION
            │  (lots livrés un à un)
            │        │
            │        ▼
            │  PLAN implemented
            │  (date de règlement,
            │   renommé YYYY-MM-DD-…)
            │
            └──> Des sujets adjacents surgissent pendant l'implémentation
                 → voir § « Pendant l'implémentation » ci-dessous
```

## Router une idée neuve

Tu as une idée, une douleur observée, un retour utilisateur, un constat de code. Où ça va ?

```
                NOUVELLE IDÉE
                      │
                      ▼
        Est-ce un fait technique / une règle
        métier non-évidente que tu viens d'apprendre ?
                      │
                  ┌───┴────┐
                 OUI      NON
                  │         │
                  ▼         ▼
        lessons-technical /  Un item de backlog / plan
        lessons-domain        in-progress existant
        (entrée datée)        couvre-t-il déjà ce sujet ?
                                   │
                               ┌───┴───┐
                              OUI     NON
                               │       │
                               ▼       ▼
                       Ajouter là   Décision : est-ce
                       (follow-up   architectural
                       de plan, ou  ET mûr ?
                       sous-item        │
                       de backlog)  ┌───┴───┐
                                   OUI     NON
                                    │       │
                                    ▼       ▼
                                 ADR +    Item de backlog
                                 plan     (voir § Granularité
                                 (trajet  pour la forme : une
                                 lourd)   ligne, un fichier
                                          court, ou groupé)
```

**La règle d'or pour les idées fraîches** :

> *« Est-ce que ce truc va guider une future décision (= ADR + plan) ? Est-ce une douleur à traiter un jour (= backlog) ? Ou une connaissance à ne pas réoublier (= lessons-*) ? »*

Vérifications avant de créer un nouvel item :
- **Doublon ?** Grep le slug ou le mot-clé principal dans `docs/backlog/` et `docs/plans/`. Si un item adjacent existe → l'ajouter dedans ou en sous-item d'un bundle, **pas** un nouveau fichier.
- **Sous-thème d'un bundle PRINCIPAL existant ?** → une ligne sous le PRINCIPAL plutôt qu'un fichier dédié (voir § Granularité, Pattern 3).

## Quand ouvrir quoi

| Tu as… | Tu ouvres… | Forme |
|---|---|---|
| Une idée / douleur pas encore mûre, décision pas prête | Un **item de backlog** | `docs/backlog/<slug>.md`, format libre |
| Une décision architecturale formelle à prendre (alternatives + conséquences) | Une **ADR** | `docs/adr/NNNN-<slug>.md`, `status: proposed` |
| Une ADR vient d'être acceptée et tu vas attaquer l'implémentation | Un **plan compagnon** | `docs/plans/<slug>.md`, `status: in-progress`. Renommé `YYYY-MM-DD-<slug>.md` une fois `implemented`/`rejected` |

L'ADR est **courte** — elle décrit *ce* qu'on choisit et *pourquoi*. Le plan est **long** — il porte le *comment*, les *alternatives détaillées*, les *lots* d'implémentation, et l'*historique vivant* du chantier.

### Ne pas pré-attribuer un numéro d'ADR dans un item de backlog

Quand un item de backlog est candidat à devenir une ADR, la tentation est d'écrire dans son corps *« candidat à devenir ADR NNNN »*, en anticipant le prochain numéro libre. **Ne le fais pas.** Les ADR s'ouvrent dans l'ordre où les décisions sont réellement prises, pas dans l'ordre où les items de backlog les anticipent. Le numéro que tu réserves *aujourd'hui* peut être pris par une autre ADR *demain*, et ta référence devient silencieusement fausse.

**À la place** :
- Utilise une formulation neutre : *« à transformer en ADR »*, *« future ADR dédiée »*, *« candidat à une ADR une fois attaqué »*.
- Si tu **dois** signaler un numéro pour orienter le lecteur, ajoute `(numéro provisoire, à reconfirmer à l'ouverture)`.
- Au moment d'**ouvrir** l'ADR, choisis le prochain numéro libre et corrige l'item de backlog en même temps si besoin.

## Trajet léger vs trajet lourd

**Tous les sujets ne méritent pas une ADR + plan.** La majorité des items de backlog sont des **fixes / mini-features** traités en commit direct (peut-être une PR si non-trivial), sans cérémonial.

| Trajet | Quand | Cycle |
|---|---|---|
| **Léger** | bug à périmètre clair, ajustement UX, dette technique localisée, audit en batch, effort < 1 jour, changement de code localisé | item de backlog → fix direct (PR) → item passe en *Référence (clos)* avec « résolu via commit XYZ » |
| **Lourd** | choix entre plusieurs options doctrinales, effort > 1 jour ou plusieurs surfaces, instaure un pattern réutilisable, la décision elle-même mérite une trace pour les futurs contributeurs | item de backlog → ADR `proposed` → plan compagnon `in-progress` → lots livrés → plan `implemented` → item en référence |

**Test rapide** : *si tu peux résumer ce qu'il faut faire en une phrase et l'envoyer en message de commit, c'est léger. Si tu dois écrire un paragraphe pour expliquer pourquoi l'option X est meilleure que Y, c'est lourd.*

## Granularité des items de backlog

Le backlog n'est **pas** strictement « un fichier = un sujet ». Selon la substance, **3 formes valides** :

### Pattern 1 — Fichier individuel court (~10-50 lignes)

Quand le fix a quelques détails à capturer (call site exact, cause racine, alternatives écartées). Une ligne dans le README backlog pointant vers ce fichier.

### Pattern 2 — Fichier groupé thématique (1 fichier, N sous-items en liste)

Quand **3+ micro-items** partagent un thème. **Pas un fichier par sous-item** — un seul fichier avec une checklist `- [ ] ...` à l'intérieur, chaque ligne courte (~1-3 lignes max). Une seule ligne dans le README backlog pointant vers le fichier groupé.

### Pattern 3 — Bundle PRINCIPAL + fichiers de sous-items séparés

Quand **chaque sous-item a sa propre substance** (50+ lignes utiles, alternatives non triviales) et qu'ils sont rattachés à un thème majeur (souvent une future ADR).

Le **PRINCIPAL** est le point d'entrée unique du bundle ; chaque sous-item a son propre fichier, avec une bannière en tête `> **Sous-item du bundle [<primaire>](primaire.md)**`. Le PRINCIPAL agrège la liste des sous-items en tête.

### Quel pattern utiliser ?

| Substance de chaque item | Pattern |
|---|---|
| **1-3 lignes** suffisent pour décrire l'item | **Ajouter une ligne** à un fichier groupé existant (Pattern 2). Si aucun thème ne colle, un fichier individuel court |
| **5-50 lignes** d'analyse / contexte | **Fichier individuel** (Pattern 1) |
| **50+ lignes** par sous-item, alternatives à expliquer, rattaché à un thème majeur | **Bundle PRINCIPAL + sous-items** (Pattern 3) |

**Règle pratique** : commencer simple (une ligne ou un fichier individuel). Promouvoir vers un pattern plus structuré seulement quand la matière le justifie.

## Pendant l'implémentation : où vont les choses qui émergent ?

C'est *le* trou de doctrine classique. Cinq cas, cinq destinations :

| Cas | Destination | Section précise |
|---|---|---|
| **Option écartée par doctrine** (« on a décidé que non, et voici pourquoi ») | Reste dans le plan | `## Alternatives considérées` (avec le pourquoi) |
| **Sous-question résolue pendant l'implémentation** | Reste dans le plan | `## Questions ouvertes` (rayer en `~~résolue~~` + une ligne) ou `## Journal de décisions` (entrée datée) |
| **Point à traiter plus tard, qui reste *dans la même conversation*** | Reste dans le plan | `## Follow-ups surfacés pendant l'implémentation` — devient soit un Lot N+1, soit migré en backlog *à la clôture du plan* |
| **Point indépendant, périmètre différent, besoin de son propre cycle** | Un **item de backlog** dédié | Nouveau `docs/backlog/<slug>.md` avec en tête `_Surfacé pendant l'implémentation du [plan de l'ADR NNNN](...)._` |
| **Point qui mérite son propre raisonnement architectural** | Une **nouvelle ADR** | Mentionné dans le `related-adrs:` du plan d'origine |

### La règle d'or pour les 3 derniers cas (la vraie zone grise)

> **Si la conversation qui finira par résoudre ce point sera la même que celle qui clôture le plan en cours → reste en Follow-up.**
> **Si elle aura besoin d'un raisonnement neuf / un nouvel agenda → item de backlog.**
> **Si elle aura besoin d'un nouveau cadre architectural → ADR.**

## Que devient un item de backlog promu en ADR ?

Symétrique de la section précédente. Quand un item de backlog mûrit jusqu'à mériter une ADR + plan, il **ne disparaît pas instantanément** — il évolue selon l'état de l'ADR :

| État de l'ADR | Ce que devient l'item de backlog |
|---|---|
| Pas encore promu | Vit normalement dans le backlog actif |
| **ADR `proposed`, ouverte depuis l'item de backlog** | L'item **reste actif** ; ajouter une mention `_À convertir en ADR NNNN_` dans son corps |
| **ADR `accepted`, plan `in-progress`** | Le **plan devient la source de vérité** du chantier. L'item de backlog reste mais devient un **pointeur historique** — le travail se passe désormais dans le plan |
| **ADR `accepted`, plan `implemented`** | L'item de backlog passe dans la section **« Référence (clos) »** du README backlog, avec une bannière `**Statut** : résolu par [ADR NNNN] + [plan compagnon]` |
| **ADR `rejected`** | L'item de backlog revient à son état actif initial (ou est lui-même rejeté si la substance est jugée non pertinente) |
| **ADR `deferred`** | L'item de backlog reste actif tant que le sujet l'est ; mention « ADR NNNN deferred, déclencheur de réveil documenté » |

## Clôturer un plan : mini-checklist

Avant de passer un plan en `implemented` :

1. [ ] Chaque Lot de `## Lots d'implémentation` est soit ✅ livré (référencé dans `## Progression`), soit explicitement **gated future** dans le Lot lui-même.
2. [ ] Chaque entrée de `## Questions ouvertes` est soit résolue (rayée), soit explicitement déplacée en `## Follow-ups`.
3. [ ] Les `## Follow-ups surfacés pendant l'implémentation` survivants ont chacun une destination explicite : traité dans le Lot final, migré en **item de backlog** (créer le fichier, le référencer ici), ou explicitement marqué *gated future* avec un déclencheur documenté.
4. [ ] Le frontmatter passe à `status: implemented` + `settled: YYYY-MM-DD`.
5. [ ] Fichier renommé avec un préfixe de date : `git mv <slug>.md YYYY-MM-DD-<slug>.md`. Tous les liens entrants mis à jour.
6. [ ] L'entrée correspondante dans [`docs/plans/README.md`](plans/README.md) est mise à jour (`status` + nouveau nom).
7. [ ] Les leçons non-évidentes sont capturées dans [`lessons-technical.md`](lessons-technical.md) ou `lessons-domain.md`, datées.

Un plan `implemented` est **gelé** : son contenu n'est plus édité ensuite (sauf typos). C'est un record archéologique. Pour revisiter, ouvrir une nouvelle ADR + plan.

## Statuts particuliers

### ADR `deferred`

L'ADR a été examinée mais mise en sommeil. Les déclencheurs de réveil sont documentés dans le corps de l'ADR (« quand un CVE pointe son nez », « quand un utilisateur signale X », etc.). L'ADR survit comme référence, pas rediscutée tant qu'un déclencheur ne se déclenche pas.

Le plan compagnon d'une ADR `deferred` reste `in-progress` (la convention des plans ne supporte que `in-progress | implemented | rejected`). Le statut réel est documenté dans l'en-tête de l'ADR.

### ADR `superseded`

Une ADR plus récente remplace l'ancienne. Le champ `superseded-by: NNNN` pointe vers la remplaçante. L'ancienne ADR survit comme référence historique.

### Plan `rejected`

Le plan a été ouvert mais le chantier n'a jamais été attaqué et a été abandonné (typiquement : l'ADR est passée `rejected` ou `deferred` de façon permanente). Frontmatter `status: rejected` + `settled: YYYY-MM-DD` + renommage `YYYY-MM-DD-<slug>.md`.

## Mémo récap

- **Plan** = le *comment* d'une ADR acceptée. Long. Vivant.
- **ADR** = la *décision*. Courte. Gelée une fois acceptée.
- **Item de backlog** = un sujet *pas encore* prêt pour une ADR, *ou* un follow-up indépendant migré d'un plan.
- **Sections de plan canoniques** (voir [`plans/template.md`](plans/template.md)) — chacune a sa vocation. Quand un point émerge, demander : « ça ressemble à quelle section ? »
