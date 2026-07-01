# Stratégie de persistance

Où Claude (ou tout assistant IA travaillant sur ce dépôt) doit écrire les choses qui doivent survivre à une seule conversation.

<!-- FULL-ONLY --> <!-- paragraphe du hook memory-block — à garder seulement si le hook a été activé au moment du bootstrap -->
**La mémoire privée auto de Claude (`~/.claude/projects/<projet>/memory/`) est interdite sur ce projet** — tout ce qui mérite d'être retenu mérite d'être versionné, lisible par les autres contributeurs, et review-able en PR.

Un hook `PreToolUse` dans `.claude/settings.json` bloque toute écriture sous le répertoire mémoire et renvoie ici.
<!-- /FULL-ONLY -->

<!-- FULL-ONLY -->
> **Voir aussi** : [`workflow.md`](workflow.md) — ce document dit *où* mettre les choses ; le workflow dit *quand* (cycle de vie ADR ↔ plan ↔ backlog, et où vont les points qui émergent en cours d'implémentation).
<!-- /FULL-ONLY -->

## Matrice — où va quoi

| Type d'information | Destination | Notes |
|---|---|---|
<!-- FULL-ONLY --> | **Décision architecturale formelle** (mérite un titre + alternatives + conséquences) | [`docs/adr/`](adr/) (numérotées) + `docs/plans/` compagnon | suivre [`docs/adr/template.md`](adr/template.md) | <!-- /FULL-ONLY -->
| **Item à traiter plus tard** (rollout, dette, refacto, point différé) | [`docs/backlog/`](backlog/) — un fichier par sujet | format libre, suivre les conventions des fichiers existants |
| **Leçon technique non-évidente** (piège, contrainte d'outillage, subtilité de librairie) | [`docs/lessons-technical.md`](lessons-technical.md) | section datée |
| **Règle métier non-évidente** *(si ce projet a un `lessons-domain.md`)* | [`docs/lessons-domain.md`](lessons-domain.md) | section datée |
| **État courant du système** (architecture, comment ça marche aujourd'hui) | [`docs/architecture.md`](architecture.md) | mise à jour quand le réel change |
| **Setup / build / déploiement** | [`docs/operations.md`](operations.md) | |
| **Nouvelle question fréquente** type « Question → Lire » | ajouter une ligne dans la table de [`CLAUDE.md`](../CLAUDE.md) | rester court — CLAUDE.md est l'index, pas le contenu |
<!-- FULL-ONLY --> | **Outillage IA** (plugins, skills, hooks, slash commands utilisés ou à adopter) | [`docs/claude-code-tooling.md`](claude-code-tooling.md) | | <!-- /FULL-ONLY -->
<!-- FULL-ONLY --> | **Préférence individuelle d'un contributeur** (style de prompt, alias, choix perso non partagés par toute l'équipe) | [`docs/prefs/<login>.md`](prefs/) | un fichier par contributeur — committé pour que Claude le charge à chaque session ; les autres contributeurs le voient mais ne l'appliquent pas | <!-- /FULL-ONLY -->

## Quand rien ne colle

Si aucune ligne ne correspond à ce que tu veux retenir, **demande à l'utilisateur avant d'écrire**. N'invente pas de nouvelle destination ad hoc.

<!-- FULL-ONLY -->
## Préférences individuelles (`docs/prefs/<login>.md`)

Idée : chaque contributeur a un fichier portant son login (identifiant de session local, ex. `$USER` ou `git config user.name`). Il contient :
- préférences de communication (longueur des réponses, langue, niveau de verbosité)
- préférences de workflow (stratégie de branches, format des messages de commit, souhait ou non de trailers co-auteur, etc.)
- raccourcis personnels (chemins, alias, commandes spécifiques à l'environnement local)

Il ne contient **pas** :
- une convention que toute l'équipe doit suivre → `CLAUDE.md` ou un autre doc partagé
- une décision sur le projet → `docs/adr/` ou `docs/backlog/`
- une leçon technique → `docs/lessons-*.md`

Claude charge automatiquement le fichier correspondant au login local au début de chaque session.
<!-- /FULL-ONLY -->

## Pourquoi cette règle

- **Visibilité** : les conventions et préférences sont auditables en revue de PR, pas cachées dans une mémoire privée.
- **Continuité** : ce qui matche une session sur cette machine matche aussi un clone frais sur une autre.
- **Onboarding** : un nouveau contributeur clone le dépôt, lit `CLAUDE.md`, et ses préférences sont déjà documentées (ou il en crée).
- **Versionnement** : `git log` donne l'historique des décisions. La mémoire privée n'a pas d'historique consultable.
