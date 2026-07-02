# Versioning et rétro-propagation

## Le problème

Aujourd'hui, un projet bootstrapé ne garde aucune trace de la révision du kit qui l'a généré. Deux conséquences :
- Impossible de savoir, des mois plus tard, si une amélioration ultérieure du kit (fix de bug, nouveau module) a des chances de s'appliquer à ce projet sans tout re-diffter à l'aveugle.
- La limite déjà documentée dans `ADAPTING.md` ("pas de rétro-propagation automatique, diff manuel") est *pire* qu'elle n'y paraît : un diff manuel suppose de savoir depuis quel point de départ on part, ce qui n'est actuellement pas le cas.

## Décision prise (2026-07) — SHA git plutôt que semver

Tamponner le SHA du commit du kit (`git -C KIT_ROOT rev-parse HEAD`, capturé en Phase 4) dans un fichier `.claude-project-kit-version` à la racine du projet cible, plutôt que de maintenir un numéro de version sémantique à la main.

**Pourquoi pas un semver classique + CHANGELOG dédié** : ça demanderait une discipline manuelle (bump à chaque commit substantiel) qui sera oubliée — exactement le genre de mécanisme qui s'auto-sabote avec le temps. Le SHA git est automatique, précis, et permet un `git diff <sha>..HEAD -- templates/<lang>/` direct pour voir exactement ce qui a changé depuis le bootstrap d'un projet donné.

**Limite assumée initialement, levée le 2026-07-01** : un SHA n'est pas lisible humainement. `VERSION` (semver, `0.3.0` au 2026-07-02) + `CHANGELOG.md` construits — le SHA reste la source de vérité *précise* pour le diff mécanique de `/propose-kit-improvement`, le semver+changelog sert la lecture humaine ("qu'est-ce qui a changé depuis que j'ai bootstrapé mon projet ?"). Bump manuel et délibéré, pas à chaque commit — sauf le chemin `/propose-kit-improvement` (Phase 6), qui alimente `[Unreleased]` automatiquement à chaque changement externe accepté, précisément pour ne pas dépendre de la mémoire du mainteneur sur ce chemin-là.

## Application sélective des changements — ✅ résolu (2026-07-01)

Construit : `/pull-kit-updates`, symétrique de `/propose-kit-improvement`. Fusion à 3 voies (BASE = original au SHA tamponné, MIEN = fichier réel du projet, NOUVEAU = kit HEAD actuel) sur la même liste stricte de fichiers propres au kit. La plupart des cas sont sans ambiguïté (MIEN==BASE → fast-forward ; NOUVEAU==BASE → rien à faire) ; l'arbitrage (les deux ont divergé de BASE) présente les deux diffs et laisse l'utilisateur choisir, avec une tentative de fusion structurelle si les zones modifiées ne se recouvrent pas. Le tampon avance après relecture, que tout ait été accepté ou non — une divergence refusée devient délibérée plutôt que rejugée à chaque run.

Toujours pas construit, et volontairement : une synchronisation *automatique* façon `cookiecutter --replay` sans relecture. Les deux skills (`/propose-kit-improvement`, `/pull-kit-updates`) exigent une confirmation explicite avant d'écrire quoi que ce soit — trajet plus lourd pour l'utilisateur qu'un auto-sync, mais c'est le compromis assumé face au risque de laisser du contenu propre à un projet fuiter, ou d'écraser une personnalisation locale sans le dire.

## Remontée cross-projet (le vrai trou "auto-apprenant") — ✅ résolu (2026-07)

Construit : `/propose-kit-improvement` (généré dans chaque projet bootstrapé, profils Full et Minimal). Utilise le tampon `.claude-project-kit-version` ci-dessus pour diffter les fichiers "propres au kit" (liste stricte, jamais les fichiers de contenu projet) contre l'original, classer généralisable/spécifique/bruit, filtrer les infos personnelles, et présenter le patch à l'utilisateur pour confirmation avant toute branche/commit dans le checkout local du kit. Le push/PR reste une demande séparée et explicite — jamais automatique.

Ce qui reste ouvert : rien n'assure qu'un contributeur pense à le lancer — pas de rappel automatique, juste une commande disponible.

## Tampon étendu à profile/changelog/memoryhook — ✅ résolu (2026-07-02)

`.claude-project-kit-version` ne stockait que `sha=`/`lang=` ; le profil (Full/Minimal) et le choix changelog devaient être redéduits de la présence/absence de fichiers par `/propose-kit-improvement`/`/pull-kit-updates` lors de la normalisation — ambiguïté silencieuse entre "Minimal choisi au bootstrap" et "Full choisi puis fichiers supprimés depuis". Trouvé lors du premier run réel des 3 skills, voir `docs/backlog/first-real-run-findings.md`.

Ajout de `profile=full|minimal` et `changelog=yes|no` au tampon (Phase 4 de `bootstrap-claude-env.md`). Puis, avec l'axe `MEMORYHOOK-ONLY` (cf. anomalie A1 de `first-real-run-findings.md`), ajout d'un cinquième champ `memoryhook=yes|no` — le paragraphe d'interdiction de la mémoire privée dans `persistence-strategy.md` est désormais gaté sur ce choix (indépendant de Full/Minimal), plus sur `FULL-ONLY`. Purement additif — les deux skills miroirs retombent sur l'ancienne inférence si un champ est absent (`profile`/`changelog` par présence de fichiers, `memoryhook` par présence du hook `PreToolUse` dans `.claude/settings.json`), donc pas de rupture pour les projets déjà bootstrapés (ex. `voxtrail`, tamponné avant ces ajouts).
