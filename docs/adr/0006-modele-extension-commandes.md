---
status: accepted
date: 2026-07-06
deciders: [Plasma-AndraaX]
superseded-by:
related-adrs: [0004, 0005]
related-plans: [modele-extension-commandes]
---

# ADR 0006 — Modèle d'extensibilité des commandes du plugin

## Contexte

Depuis la bascule plugin ([ADR 0004](0004-plugin-armature.md)), les commandes d'Armature sont des skills **partagées** : installées une fois, exposées dans tous les projets, mises à jour de façon centralisée. Un projet consommateur qui veut **spécialiser** une commande n'avait, en apparence, que deux mauvaises options : **forker** la commande localement (elle se fige, perd les mises à jour du plugin — l'état de Holoon avant bascule) ou **modifier la base** (change le comportement pour *tous* les projets).

Le déclencheur réel est Holoon (installé le 2026-07-06), qui portait 6 commandes locales pré-plugin fortement personnalisées : un `changelog-draft` de release sur-mesure (multi-locale, glossaire i18n, buckets), une détection de livraison couplée au code, et des conventions maison (« pas de `Co-Authored-By` », Gitflow `--no-ff`).

L'idée initiale — chaque commande de base lit un fichier d'extension projet et l'intègre — traiterait pareil quatre natures distinctes : conventions transverses, données de config, comportement additif léger, comportement franchement différent. En **inspectant le kit avant de construire** (doctrine du repo), on constate que la brique « conventions transverses » **existe déjà** : `docs/prefs/<login>.md` (perso) et `CLAUDE.md` (équipe) sont **auto-chargés à chaque session** ; le template `prefs/README` cite explicitement « format de commit / trailers co-auteur / stratégie de branches » (mot pour mot les conventions Holoon), et trois skills (`new-adr`, `document-standards`, `dashboard`) le **consultent déjà**. Le besoin ne justifie donc pas un mécanisme d'overlay universel — qui, à vouloir tout couvrir, redeviendrait aussi fragile que le fork qu'il prétend éviter.

## Décision

Adopter un **modèle d'extensibilité à trois niveaux, sans nouvelle machinerie** :

1. **Conventions transverses** → portées par `CLAUDE.md` (équipe) et `docs/prefs/<login>.md` (perso), **déjà auto-chargés** et déjà consultés par les skills concernées. Rien à bâtir ; on garde la liberté d'étendre au fil de l'eau l'instruction « défère aux conventions du projet » dans une skill qui en aurait le besoin.
2. **Override complet** → une commande locale (`.claude/commands/<nom>.md`) qui **remplace** la skill du plugin, dans un **namespace distinct** (`/<nom>` vs `/armature:<nom>`), **assumée sans culpabilité** pour les cas où le comportement diverge vraiment (le `changelog-draft` sur-mesure de Holoon). Le plugin ne cherche pas à tout absorber.
3. **Overlay ciblé par points d'ancrage** (une skill de base lisant un `.claude/armature/<nom>.md` optionnel à des sections nommées) → **délibérément non construit**. Wake trigger : le jour où une personnalisation *additive légère* devient récurrente et pénible à maintenir à la main sur plusieurs projets.

## Conséquences

- **Positives** — aucune complexité ajoutée : le besoin « conventions » retombe sur deux fichiers déjà en place ; le cas lourd a une réponse claire et **légitime** (override, namespace distinct) plutôt qu'un contournement honteux ; on évite le piège de l'overlay universel ; la décision **arrête de re-débattre** le sujet à chaque nouveau projet fortement personnalisé.
- **Négatives** — un projet qui veut un enrichissement *additif léger* (p. ex. ajouter des cibles de stack à `new-adr`) n'a aujourd'hui, faute d'overlay, que l'override complet — plus lourd que le besoin — ou l'attente que le tier (b) soit construit ; on **assume ce trou** tant que le déclencheur n'a pas sonné. Par ailleurs l'override (c) rouvre la dette qu'on voulait fuir : une commande locale ne bénéficie pas des évolutions de la skill de base (accepté, précisément pour les cas où le comportement diverge).
- **Neutres** — le résidu du tier (a) (généraliser « consulte les conventions/prefs du projet » au-delà du seul message de commit dans les skills concernées) reste une amélioration **incrémentale ouverte**, pas un prérequis. Distinct de [`contribution-and-extension-model.md`](../backlog/contribution-and-extension-model.md) (dépôts satellites / overlays de *templates*) : la présente ADR porte sur l'extension des *commandes* par projet consommateur.

## Alternatives considérées

- **Fichier d'extension unique par commande** (l'idée de départ) — rejeté : traite quatre natures distinctes de la même façon, duplique les conventions transverses (déjà couvertes ailleurs), et l'overlay universel finit aussi fragile que le fork qu'il voulait éviter.
- **Construire tout de suite l'overlay à points d'ancrage (tier b)** — rejeté *pour l'instant* : pas de déclencheur réel — Holoon est couvert par override ; YAGNI, cohérent avec la doctrine « ne pas bâtir avant un besoin démontré ».
- **Interdire l'override local / tout absorber dans le plugin** — rejeté : un `changelog-draft` maison de 181 lignes n'est pas un enrichissement, c'est un autre workflow ; l'absorber gonflerait la base pour tous.

## Références

- ADR liées : [0004](0004-plugin-armature.md) (bascule plugin — crée le problème), [0005](0005-simplifications-post-plugin.md) (précédent d'un « non » gelé : fin de la synchro projet↔kit)
- Plans liés : [`../plans/modele-extension-commandes.md`](../plans/modele-extension-commandes.md)
- Réflexion source : [`../backlog/command-extension-mechanism.md`](../backlog/command-extension-mechanism.md)
- Mécanisme du tier (a) : [`../../plugin/templates/fr/docs/prefs/README.md.tpl`](../../plugin/templates/fr/docs/prefs/README.md.tpl)
