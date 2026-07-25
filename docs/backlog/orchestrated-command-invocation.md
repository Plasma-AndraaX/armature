# Invocation d'une commande par un orchestrateur (le trou de `disable-model-invocation`)

## Le constat

Les **8** skills du plugin portent `disable-model-invocation: true` (bootstrap, capture-lessons, changelog-capture, changelog-draft, dashboard, document-standards, new-adr, review-backlog). Ce flag interdit au *modèle* d'appeler la commande **via l'outil `Skill`, en toutes circonstances** — même quand l'utilisateur consent explicitement en langage naturel. Seul le fait que l'utilisateur **tape** `/armature:<nom>` la déclenche.

C'est une **politique uniforme** héritée de la bascule plugin ([ADR 0004](../adr/0004-plugin-armature.md)) : avant, c'étaient des `.claude/commands/` (slash-commands, déclenchées par l'humain). Le format plugin n'offre que `skills/` pour le namespace `/armature:` (Q4 du [plan armature-plugin](../plans/armature-plugin.md)), et un skill de plugin est **auto-invocable par défaut** ; le flag restaure la sémantique « commande » d'origine.

## Le problème (point utilisateur, 2026-07-25)

Le flag **sur-bloque**. Il ne distingue pas deux cas très différents :

1. **Déclenchement spontané, sans consentement, au mauvais moment** — le modèle décide tout seul de tirer `/armature:capture-lessons` en plein refacto parce que la description matche. *Indésirable* — c'est ce que le flag vise.
2. **Consentement / orchestration explicite** — soit le modèle *propose* « je lance `/armature:new-adr` ? » et n'exécute qu'après le « oui », soit une commande **explicitement lancée par l'utilisateur** (`/release`) veut **chaîner** une autre commande (`/changelog-draft`). *Parfaitement légitime.*

Le flag tue le cas (2) en collatéral. Cas concret déclencheur : le skill Holoon `/release` (Phase 4) dit « lance `/changelog-draft` » — mais le modèle qui exécute `/release` **ne peut pas** l'appeler (flag), alors qu'on est dans une orchestration voulue par l'utilisateur. Il retombe sur une réimplémentation improvisée, moins fidèle (perte de la review pause des flags + des propositions de captures définies dans l'overlay).

## Analyse : quel est l'avantage réel du blocage ?

Honnêtement, mince, et non intrinsèque au contenu des commandes :

- **Contre le cas (1)** : oui, réel — pas de mutation-surprise (`_next.md` vidé, ADR créé, bootstrap) déclenchée au mauvais moment.
- **Contre le cas (2)** : **nul**. Le risque d'effet de bord surprise est déjà neutralisé par le consentement/l'orchestration explicite.

Deux vraies raisons expliquent le choix, aucune propre à une commande :

1. **Le frontmatter n'offre qu'un binaire** : *auto-invocable* (le modèle peut tirer spontanément) **ou** *pas du tout*. Il n'existe pas de réglage intermédiaire « proposable, mais consentement requis ». Face à des commandes à effets de bord, l'auteur a pris l'extrême conservateur — défaut d'expressivité de la plateforme autant que choix.
2. **Distribution tierce** ([ADR 0004](../adr/0004-plugin-armature.md), marketplace) : l'auteur ne peut pas supposer que le modèle/la config de chaque installeur se comporte prudemment. Un blocage dur donne un comportement **uniforme et prévisible** (« ça ne se lance que si je le tape ») sur toutes les installations. Valeur réelle *pour de la distribution à des inconnus* — bien moindre sur son propre projet, où l'on fait confiance au modèle pour proposer d'abord.

Conclusion : pour un utilisateur qui veut le cas (2), le flag est un coût de collatéral pour un bénéfice qui ne couvre que le cas (1) — qu'il ne veut de toute façon pas.

## Pistes de solution

### A — Contournement zéro-modif (déjà applicable)
Un orchestrateur (`/release`) qui « réutilise » une commande `disable-model-invocation` ne l'appelle pas via l'outil `Skill` : il **lit son `SKILL.md` + son overlay projet et les exécute inline**, review pauses comprises. C'est la bonne lecture de « réutilise, ne réimplémente pas ». À **documenter explicitement** (ADAPTING.md + une phrase dans les skills orchestrateurs) pour que ce ne soit pas redécouvert à chaque fois. Ne corrige pas la cause, mais débloque immédiatement.

### B — Mode d'invocation « propose-first / consentement requis »
Si/quand la plateforme (ou une convention Armature) le permet : un troisième état entre « auto » et « jamais » — le modèle peut *proposer* la commande et ne l'exécuter qu'après consentement explicite. C'est le réglage qui manque et qui rendrait le cas (2) natif sans rouvrir le cas (1). Dépend d'une capacité côté Claude Code (à surveiller) ; sinon, l'émuler par convention de prompt dans les skills (« ne jamais auto-invoquer ; toujours proposer d'abord »).

### C — Exception d'orchestration entre commandes
Autoriser qu'une commande **explicitement lancée par l'utilisateur** en chaîne une autre marquée `disable-model-invocation`. Suppose un mécanisme de « contexte d'orchestration » que le frontmatter binaire actuel ne connaît pas — donc probablement hors de portée sans support plateforme. La piste A l'émule déjà fonctionnellement (l'orchestrateur suit la commande inline).

## Statut

**Ouvert, candidat à un futur ADR** qui réviserait la politique uniforme `disable-model-invocation` de la bascule plugin ([ADR 0004](../adr/0004-plugin-armature.md)), dans la lignée du travail d'extensibilité ([ADR 0006](../adr/0006-modele-extension-commandes.md), [0007](../adr/0007-mecanisme-extension-tier-b.md)).

**Déclencheur de réveil** : l'orchestration entre commandes devient récurrente (au-delà de `/release` → `/changelog-draft`), **ou** Claude Code introduit un mode d'invocation intermédiaire (propose-first) qui rend la piste B native. En attendant, appliquer la **piste A** (documenter le follow-inline) suffit à débloquer Holoon.

**Origine** : discussion Holoon 2026-07-25 pendant la release 26.8.4 (le `/release` de Holoon n'a pas pu chaîner `/changelog-draft`, hand-roll improvisé à la place).
