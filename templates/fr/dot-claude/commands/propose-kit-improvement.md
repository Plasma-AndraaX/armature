---
description: Diffter les fichiers issus du kit de ce projet contre la version de claude-project-kit qui l'a généré, et proposer un patch filtré et relu par l'humain vers le kit.
argument-hint: [optionnel — un indice sur ce que tu penses avoir changé, si tu le sais déjà]
---

# Proposer une amélioration au kit

Ce projet a été bootstrapé depuis `claude-project-kit`. Avec le temps, certains de ses fichiers issus du kit ont pu dériver de l'original de façons qui aideraient vraiment *tout* projet que le kit bootstrape — une instruction de skill plus claire, un fix de bug, un meilleur défaut. Ce skill trouve ces changements, filtre ce qui est spécifique à ce projet, et prépare un patch relisible. **Rien n'est commité ni poussé vers le kit sans confirmation explicite de l'utilisateur à la fin.**

$ARGUMENTS

## Phase 1 — Localiser la baseline

- Lis `.claude-project-kit-version` à la racine du projet (`sha=...`, `lang=...`, et — sur un tampon récent — `profile=full|minimal`, `changelog=yes|no` et `memoryhook=yes|no`). S'il n'existe pas, ce projet précède le tamponnage de version — dis à l'utilisateur qu'il n'y a pas de baseline fiable pour diffter et arrête-toi (ne devine pas). Si `profile=`/`changelog=`/`memoryhook=` sont absents (tampon d'avant leur ajout), déduis-les comme avant : `profile`/`changelog` de la présence/absence des fichiers Full-only, `memoryhook` de la présence du hook memory-block (`PreToolUse`) dans `.claude/settings.json`.
- Résous `KIT_ROOT` : variable d'env `$CLAUDE_PROJECT_KIT_HOME` si définie, sinon `/mnt/c/dev/claude-project-kit`, sinon demande à l'utilisateur le chemin de son checkout du kit.
- Vérifie que le SHA tamponné existe encore dans l'historique local du kit (`git -C KIT_ROOT cat-file -e <sha>`). Si non (rebase, clone shallow, historique élagué), explique précisément pourquoi à l'utilisateur et arrête-toi plutôt que de diffter silencieusement contre autre chose.

## Phase 2 — L'ensemble candidat (fichiers propres au kit uniquement)

**Ne considère jamais que ceux-ci** — n'ouvre, ne diffte, ni ne cite jamais quoi que ce soit en dehors de cette liste :
- `CLAUDE.md` — mais **seulement** sa prose boilerplate/instructionnelle et la structure de la table de routage (formulation des lignes, quelles lignes existent). Jamais ses valeurs substituées (nom du projet, description, stack) ni ce qui a été rempli par l'analyse de code de ce projet (les commandes de build réelles ; le pointeur vers Architecture est OK, pas le contenu réel).
- `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md` (si présent)
- `docs/adr/template.md`, `docs/adr/README.md` (son squelette générique seulement — jamais une ligne d'ADR qu'un projet a réellement ajoutée)
- `docs/plans/template.md`, `docs/plans/README.md` (même réserve)
- `docs/prefs/README.md` (l'explication générique du mécanisme, jamais le fichier réel d'un contributeur)
- Chaque `.claude/commands/*.md` présent (y compris ce fichier)
- `tools/generate-dashboard.py` (si présent)
- `claude.sh`, `.env.claude.example`, `.gitignore`, `tools/session-end-capture.sh` (si présent)
- `.claude/settings.json` — **seulement** la partie hook memory-block et le bloc du hook `SessionEnd` de capture (y compris son argument de mode `message`/`auto`), jamais `enabledPlugins` ni le reste (ce sont les choix propres à ce projet). **Cas particulier pour le bloc `SessionEnd`** : il n'existe dans aucun fichier `.tpl` statique — il est assemblé dynamiquement par la prose de `.claude/commands/bootstrap-claude-env.md` (§ Phase 4, *« Assembling `.claude/settings.json` »*, hors de la liste candidate elle-même). Sa BASE se reconstruit en lisant ce paragraphe et en substituant le mode `message` (celui montré dans le texte), pas via un `git show` sur un chemin candidat.

**Ne jamais considérer, en aucune circonstance, même si ça a l'air générique** : `docs/architecture.md`, `docs/operations.md`, `docs/coding-standards.md`, `docs/lessons-technical.md`, `docs/lessons-domain.md`, tout ce qui est sous `docs/backlog/`, tout fichier numéroté sous `docs/adr/` ou `docs/plans/` (les vraies ADR/plans, pas les gabarits), les fichiers `docs/prefs/<login>.md`, `docs/changelog/_next.md` ou toute entrée datée du changelog, `docs/claude-code-tooling.md`. Ce sont du contenu projet par construction — il n'y a aucun scénario où les diffter pour remontée est correct, donc ils sont exclus structurellement plutôt que laissés au jugement.

## Phase 3 — Diffter chaque candidat

Pour chaque fichier candidat présent dans ce projet :
1. Récupère le contenu original du gabarit : `git -C KIT_ROOT show <sha>:templates/<lang>/<chemin-mappé>` (remapper `.claude/` vers `dot-claude/` ; pour savoir si le chemin prend un suffixe `.tpl`, voir `CONTRIBUTING.md` § *Which files get a `.tpl` suffix* dans le kit — ne redevine pas la règle).
2. **Normaliser avant de comparer** — le gabarit original peut contenir des placeholders `{{PROJECT_NAME}}`/`{{PROJECT_ONE_LINER}}`/`{{PRIMARY_STACK}}` et des marqueurs `FULL-ONLY`/`MINIMAL-ONLY`/`CHANGELOG-ONLY`/`MEMORYHOOK-ONLY` qui ont été résolus pour le profil/langue/choix changelog/choix hook-mémoire de ce projet au moment du bootstrap. Résous l'*original* de la même façon (substitue le vrai nom/description/stack de ce projet, retire les marqueurs selon le `profile=`/`changelog=`/`memoryhook=` lus en Phase 1) avant de diffter — sinon chaque fichier montre des différences fantômes qui ne sont que de la résolution de profil, pas de vrais changements. Vérifie aussi qu'aucun commentaire d'échafaudage non lié à un marqueur (ex. un commentaire HTML expliquant à quoi sert une section, présent dans le gabarit mais retiré par le bootstrap réel) ne traîne dans ta version normalisée — sinon il apparaît comme un faux hunk.
3. Ce qui reste après normalisation est le vrai diff. Attends-toi à ce qu'il soit vide ou minuscule la plupart du temps pour la plupart des fichiers — c'est normal, pas un bug.

## Phase 4 — Classer et filtrer

**Grain de classification** : quand un hunk unifié mélange plusieurs changements logiquement distincts (ex. suppression d'un commentaire d'échafaudage + vraie amélioration de formulation dans le même bloc `@@`), sous-découpe-le et classe chaque partie séparément plutôt que de classer tout le hunk d'un bloc.

Pour chaque vrai hunk (ou sous-hunk) de diff :
- **Amélioration généralisable** : se lit pareil quel que soit le projet — une instruction plus claire, une typo corrigée, un cas limite corrigé, un nouvel exemple réellement utile. Candidat à proposer.
- **Personnalisation propre au projet** : n'a de sens que dans le contexte de *ce* projet — mentionne son domaine réel, des noms, son architecture, ou une préférence propre à cette équipe. Écarte-le, ne le montre même pas comme "rejeté" en citant son contenu — note juste dans la synthèse que N changements propres au projet ont été trouvés et exclus.
- **Bruit** : ne diffère qu'à cause d'une résolution de placeholder/marqueur que la Phase 3 aurait dû déjà normaliser, ou un reformatage trivial sans changement sémantique. Écarte-le.

Pour ce qui survit encore après ce filtre, fais un dernier passage spécifiquement à la recherche de **secrets, credentials, noms personnels, termes propres à une entreprise, hostnames/URLs internes, ou chemins de fichiers qui révèlent quelque chose de privé** — même à l'intérieur d'un changement par ailleurs généralisable. Rédige en le masquant ou écarte le hunk si tu en trouves ; dans le doute, écarte plutôt que de supposer que c'est correct.

## Phase 5 — Présenter avant de faire quoi que ce soit

Montre à l'utilisateur, groupé par fichier : ce qui a survécu au filtre, une raison en une ligne pour laquelle c'est généralisable, et le diff proposé littéral. Indique aussi, brièvement, combien de hunks ont été trouvés et exclus comme propres au projet (sans citer leur contenu) et combien comme bruit. **Ne crée pas de branche, ne commite pas, ne touche pas au checkout du kit avant que l'utilisateur ait explicitement relu et confirmé** — il peut accepter, rejeter, ou éditer chaque hunk individuellement.

Si rien ne survit au filtre, dis-le clairement et arrête-toi — "rien de généralisable trouvé ce passage" est un résultat normal et bon.

## Phase 6 — Appliquer, localement, seulement après confirmation

Pour chaque hunk confirmé :
- Édite le fichier correspondant sous `KIT_ROOT/templates/<lang>/...` (ou le fichier agnostique de la langue, ex. `.claude/commands/bootstrap-claude-env.md` lui-même si c'est ce qui a changé) — en réinsérant les tokens `{{PLACEHOLDER}}` et les marqueurs de profil exactement là où l'original les avait. **Ne jamais laisser une valeur concrète propre à ce projet fuiter dans le gabarit partagé** — si l'original avait un placeholder à cet endroit, l'édition doit restaurer le placeholder, pas coder en dur la valeur de ce projet.
- Si le même fix s'applique plausiblement aussi à l'autre variante de langue et n'était pas lui-même une traduction, dis-le et propose de rédiger l'édition équivalente là-bas — conformément à l'attente de `CONTRIBUTING.md` que `templates/en/` et `templates/fr/` avancent ensemble.
- Crée une branche dans `KIT_ROOT` (ex. `propose/<slug-court>`) depuis son HEAD actuel (pas depuis le SHA tamponné — le kit a probablement avancé depuis le bootstrap) et commite les changements acceptés avec un message clair.
- Si `KIT_ROOT/CHANGELOG.md` existe, ajoute une ligne par changement accepté sous sa section `## [Unreleased]` (crée la section si elle dit "(nothing yet)") — langage clair, même registre que le reste du fichier. C'est le seul chemin censé alimenter le changelog du kit sans dépendre de la mémoire du mainteneur.
- Lance `python3 tools/lint-templates.py` dans `KIT_ROOT` et montre le résultat. S'il échoue, corrige avant de présenter la branche comme prête, ou dis-le clairement à l'utilisateur si tu ne peux pas.

## Phase 7 — Le push/PR est une demande séparée et explicite

Ne pousse et n'ouvre jamais de PR automatiquement. Demande à l'utilisateur s'il veut :
- Pousser la branche maintenant (nécessite un remote configuré et des credentials déjà disponibles — ne provisionne ni ne va chercher un secret toi-même ; si aucun n'est disponible, dis-le et laisse la branche locale), puis éventuellement ouvrir une PR (`gh pr create` si `gh` est disponible et qu'un host de PR est configuré), ou
- La laisser en branche locale et lui dire exactement quoi lancer quand il sera prêt.

## Ce que ce skill ne fait PAS

- Il ne touche jamais à quoi que ce soit de la liste d'exclusion dure, quel que soit à quel point un changement là-dedans semble générique.
- Il ne pousse ni n'ouvre de PR sans une confirmation séparée et explicite au-delà de la relecture en Phase 5.
- Il ne fabrique pas un résultat "rien à proposer" comme un échec — la plupart des passages devraient trouver peu ou rien, et c'est très bien ainsi.
- Il ne tente rien si le tampon de version est absent ou si son SHA est inaccessible — pas de devinette best-effort contre la mauvaise baseline.
