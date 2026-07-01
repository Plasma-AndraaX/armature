---
description: Tirer les améliorations apportées à claude-project-kit depuis le bootstrap de ce projet, en fusionnant à 3 voies avec toute personnalisation locale des mêmes fichiers propres au kit.
argument-hint: [optionnel — un indice sur ce que tu penses avoir changé côté kit]
---

# Tirer les mises à jour du kit

L'image miroir de `/propose-kit-improvement` : ce skill-là envoie des changements *de* ce projet *vers* le kit ; celui-ci ramène des changements *du* kit *vers* ce projet. Même discipline de relecture avant écriture — **rien n'est appliqué à ce projet sans confirmation explicite**.

$ARGUMENTS

## Phase 1 — Localiser la baseline et l'état actuel du kit

- Lis `.claude-project-kit-version` à la racine du projet (`sha=...`, `lang=...`). S'il est absent, il n'y a pas de baseline pour diffter — dis-le à l'utilisateur et arrête-toi (ne devine pas).
- Résous `KIT_ROOT` : variable d'env `$CLAUDE_PROJECT_KIT_HOME` si définie, sinon `/mnt/c/dev/claude-project-kit`, sinon demande.
- Calcule `NEW_SHA = git -C KIT_ROOT rev-parse HEAD`. S'il est égal au `sha` tamponné, dis à l'utilisateur que le kit n'a pas bougé depuis le bootstrap et arrête-toi — rien à tirer.
- Vérifie que le `sha` tamponné est encore accessible dans l'historique de `KIT_ROOT` (`git -C KIT_ROOT cat-file -e <sha>`). Sinon, explique précisément pourquoi et arrête-toi plutôt que de diffter contre la mauvaise chose.

## Phase 2 — Le même ensemble candidat que `/propose-kit-improvement`

**Cette liste doit rester identique à celle de la Phase 2 de `propose-kit-improvement.md` — si tu édites l'une, édite l'autre.**

Candidats (propres au kit) : `CLAUDE.md` (prose boilerplate/instructionnelle et structure de la table de routage seulement, jamais les valeurs substituées ni le contenu d'analyse de code), `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md`, `docs/adr/template.md`, `docs/adr/README.md` (squelette générique seulement), `docs/plans/template.md`, `docs/plans/README.md` (même réserve), `docs/prefs/README.md`, chaque `.claude/commands/*.md`, `tools/generate-dashboard.py`, `claude.sh`, `.env.claude.example`, `.gitignore`, `tools/session-end-capture.sh` (si présent), et — seulement dans `.claude/settings.json` — la partie hook memory-block et le bloc du hook `SessionEnd` de capture (y compris son argument de mode `message`/`auto`), jamais `enabledPlugins` ni le reste.

Jamais considérés, exclus structurellement : `docs/architecture.md`, `docs/operations.md`, `docs/coding-standards.md`, `docs/lessons-technical.md`, `docs/lessons-domain.md`, tout ce qui est sous `docs/backlog/`, les fichiers numérotés sous `docs/adr/`/`docs/plans/`, les fichiers `docs/prefs/<login>.md`, `docs/changelog/_next.md` et les entrées datées, `docs/claude-code-tooling.md`, `enabledPlugins`/le reste de `.claude/settings.json`.

**Filtre de pertinence** : ne considère un chemin candidat que s'il est déjà présent dans ce projet, ou constituerait une *addition* légitime — un fichier propre au kit qui n'existait pas au bootstrap de ce projet (une capacité ajoutée au kit depuis) et pertinent pour le profil réel de ce projet. Déduis la pertinence du profil de ce qui est réellement présent (ex. si `docs/workflow.md` ou un fichier type `.claude/commands/new-adr.md` existe déjà, ce projet est profil Full-équivalent pour ce besoin) plutôt que de faire confiance à une supposition périmée — la forme d'un projet a pu changer depuis le bootstrap.

## Phase 3 — Résolution à 3 voies par candidat

Pour chaque chemin candidat pertinent, rassemble trois versions, toutes normalisées (placeholders substitués avec le vrai nom/description/stack de *ce* projet, marqueurs `FULL-ONLY`/`MINIMAL-ONLY`/`CHANGELOG-ONLY` résolus selon le vrai profil/choix changelog de ce projet — même normalisation que `/propose-kit-improvement`) :
- **BASE** — `git -C KIT_ROOT show <sha-tamponné>:templates/<lang>/<chemin-mappé>`, normalisé.
- **NOUVEAU** — `git -C KIT_ROOT show <NEW_SHA>:templates/<lang>/<chemin-mappé>`, normalisé. Si le chemin n'existe pas à `NEW_SHA`, le kit l'a supprimé — signale-le comme "le kit a retiré ce fichier" plutôt que de l'ignorer silencieusement.
- **MIEN** — le contenu réel actuel du fichier du projet, ou "absent" s'il n'a jamais été généré (non pertinent pour ce projet) ou a été supprimé.

Classe :
- **MIEN absent, NOUVEAU est une vraie addition** → propose d'ajouter le nouveau fichier.
- **MIEN absent, non pertinent pour ce projet** → ignore silencieusement.
- **MIEN == NOUVEAU déjà** → déjà à jour, ignore (compte dans la synthèse, sans détailler).
- **MIEN == BASE, NOUVEAU ≠ BASE** → mise à jour propre : aucune personnalisation locale à perdre. Propose d'appliquer NOUVEAU.
- **MIEN ≠ BASE, NOUVEAU == BASE** → le projet a personnalisé ça localement et le kit n'y a pas touché depuis — rien à tirer ici (la personnalisation reste).
- **MIEN == BASE == NOUVEAU** → rien n'a changé nulle part, ignore.
- **MIEN ≠ BASE et NOUVEAU ≠ BASE — vrai arbitrage** (le cas que l'utilisateur attend rare : "a priori ils ne sont pas censés changer"). Tente d'abord une fusion structurelle : si les zones modifiées dans MIEN-vs-BASE et NOUVEAU-vs-BASE ne se recouvrent pas, fusionne proprement les deux changements et propose le résultat fusionné. Si elles se recouvrent, ou si le non-recouvrement est ambigu, ne devine pas — présente les deux diffs côte à côte (MIEN vs BASE, NOUVEAU vs BASE) et laisse l'utilisateur choisir : garder le mien (ignorer ce fichier), prendre la version du kit (perdre la personnalisation locale), ou relire un brouillon fusionné que tu proposes.
- **Le kit a supprimé un fichier que ce projet a encore** → signale-le, demande s'il faut le supprimer localement aussi ou le garder (la suppression n'est jamais automatique).

## Phase 4 — Présenter avant de toucher à quoi que ce soit

Résume : combien de mises à jour propres, combien de nouveaux fichiers proposés, combien déjà à jour ou sans rien à tirer (comptés, pas détaillés), et — la partie intéressante — combien nécessitent un arbitrage, chacun montré avec son contexte BASE/MIEN/NOUVEAU complet. **N'écris rien avant que l'utilisateur ait relu et confirmé**, fichier par fichier pour tout ce qui n'est pas trivial.

Si tout est une mise à jour propre ou qu'il n'y a rien à tirer, ça peut être une confirmation courte et rapide — ne fabrique pas de cérémonie là où elle n'est pas nécessaire.

## Phase 5 — Appliquer les changements confirmés

- Écris chaque fichier confirmé dans le projet, en resubstituant les propres valeurs de placeholder de *ce* projet et en résolvant les marqueurs pour son profil/choix changelog réel — reproduis la logique de génération de la Phase 4 de `/bootstrap-claude-env`, ne l'esquive pas.
- Pour les cas d'arbitrage résolus en "garder le mien", ne touche à rien, mais note dans la synthèse que c'est désormais une divergence connue et délibérée à partir de maintenant (pas un diff périmé non relu).
- Mets à jour la ligne `sha=` de `.claude-project-kit-version` vers `NEW_SHA` une fois la relecture terminée, **que tous les hunks aient été acceptés ou non** — un changement décliné devient une divergence intentionnelle à partir de ce point, pas quelque chose à re-débattre à chaque run futur. Ne l'avance pas si l'utilisateur abandonne avant la fin de la relecture en Phase 4.
- Si un choix "garder le mien" a l'air de valoir la peine d'être remonté, dis-le et propose de lancer `/propose-kit-improvement` ensuite — les deux skills se bouclent l'un sur l'autre.

## Ce que ce skill ne fait PAS

- Il ne touche jamais à quoi que ce soit de la liste d'exclusion dure.
- Il n'applique jamais rien sans la relecture de la Phase 4, et ne supprime jamais un fichier du projet sans un oui explicite.
- Il ne tente rien si le tampon de version est absent ou si son SHA est inaccessible dans l'historique de `KIT_ROOT`.
- Il n'essaie pas d'être malin sur un vrai conflit — dans le doute sur la sûreté d'une fusion structurelle, il demande plutôt que de combiner silencieusement deux éditions divergentes.
