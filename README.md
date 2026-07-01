# claude-project-kit

Un kit pour installer, sur n'importe quel projet informatique (n'importe quel langage/stack), l'**environnement Claude** que j'utilise sur [Holoon](https://git.andraax.com) : de la doc versionnée qui fait office de mémoire durable pour l'agent, un cycle ADR ↔ plan ↔ backlog pour tracer les décisions, et une poignée de skills qui font vivre tout ça.

Important : ce n'est **pas** un scaffold de code (pas de boilerplate Angular/React/dotnet/etc.). C'est un scaffold pour l'**environnement de travail avec Claude** — la doc, les conventions, les commandes. Le code, tu l'écris dans le langage que tu veux, à côté.

## Pourquoi ce kit existe

Sur un projet piloté avec Claude Code au long cours, deux problèmes récurrents :

1. **La mémoire privée de Claude ne suffit pas.** Elle est locale à une machine, invisible pour le reste de l'équipe (ou pour toi-même sur un autre poste), non versionnée, non review-able. Tout ce qui mérite d'être retenu — une décision, une leçon apprise à la dure, une préférence de travail — mérite d'être écrit **dans le repo**, en Markdown, comme n'importe quel autre artefact de code.
2. **"On verra plus tard" a besoin d'un endroit précis.** Sans convention, les idées qui ne sont pas prêtes à être tranchées finissent nulle part (perdues) ou partout (un `TODO` ici, un ticket là, une note Slack ailleurs). Ce kit donne trois destinations fixes — **ADR** (décision actée), **plan** (le comment d'un ADR accepté), **backlog** (pas encore mûr) — et une doctrine claire sur quand utiliser laquelle.

Le résultat, éprouvé sur plusieurs mois sur Holoon : `CLAUDE.md` sert d'index court, chaque doc a un rôle exclusif, et une nouvelle session Claude (ou un nouveau contributeur humain) retrouve tout le contexte en lisant le repo — pas en interrogeant une mémoire opaque.

## Ce que le kit installe

| Dans le nouveau projet | Rôle |
|---|---|
| `CLAUDE.md` | Index court : table "question → doc à lire". Le seul fichier que Claude charge toujours. |
| `docs/architecture.md` | Comment le système fonctionne *aujourd'hui*. Vivant. |
| `docs/operations.md` | Setup / build / run / deploy. Vivant. |
| `docs/lessons-technical.md` | Pièges techniques non-évidents, non dérivables du code. Append-only, daté. |
| `docs/lessons-domain.md` *(optionnel)* | Règles métier non-évidentes, si le projet a un domaine riche. Append-only, daté. |
| `docs/adr/` | Décisions architecturales actées — une par fichier, numérotées, gelées une fois `accepted`. |
| `docs/plans/` | Le *comment* d'un ADR accepté — vivant tant qu'`in-progress`, gelé (renommé avec préfixe date) une fois `implemented`. |
| `docs/backlog/` | Idées / dette / douleurs pas encore mûres pour un ADR. |
| `docs/workflow.md` | La doctrine : quand ouvrir un ADR vs un backlog item, où vont les points qui émergent en cours d'implémentation, checklist de clôture. |
| `docs/persistence-strategy.md` | La matrice "tel type d'info → tel fichier". Désactive la mémoire privée Claude (si tu choisis cette option). |
| `docs/prefs/<login>.md` *(profil Full)* | Préférences individuelles par contributeur, committées. |
| `docs/claude-code-tooling.md` *(profil Full)* | Inventaire des skills/plugins/hooks Claude utilisés sur ce projet. |
| `docs/dashboard.html` + `tools/generate-dashboard.py` *(profil Full)* | Vue HTML générée de l'état ADR ↔ plan ↔ backlog. |
| `.claude/settings.json` | Hook optionnel qui bloque l'écriture dans la mémoire privée Claude et renvoie vers `persistence-strategy.md`. |
| `.claude/commands/new-adr.md`, `capture-lessons.md`, `whats-left.md`, `dashboard.md` *(profil Full)* | Skills qui font vivre le système au quotidien. |

Deux profils au moment de la génération :
- **Full** — tout l'arsenal ci-dessus.
- **Minimal** — juste `CLAUDE.md`, `architecture.md`, `operations.md`, `lessons-technical.md`, `docs/backlog/README.md`, `docs/persistence-strategy.md` (matrice réduite). Pas de machinerie ADR/plan/dashboard tant que le projet n'en a pas l'usage — on peut toujours upgrader vers Full plus tard en relançant le bootstrap.

Détail des deux profils et de ce qu'il faut adapter selon ton contexte : [`ADAPTING.md`](ADAPTING.md).

## Utilisation

### Option A — depuis ce repo

```bash
cd /mnt/c/dev/claude-project-kit
claude
```
Puis, dans la session :
```
/bootstrap-claude-env /chemin/absolu/vers/mon-nouveau-projet
```
Le skill pose quelques questions (nom du projet, stack, solo/équipe, profil Full/Minimal, hook mémoire oui/non) puis écrit dans le répertoire cible — pas besoin d'y être `cd`, Claude Code écrit à des chemins absolus arbitraires.

### Option B — commande globale

Copie `template` en commande globale pour l'avoir disponible sans repasser par ce repo :
```bash
cp /mnt/c/dev/claude-project-kit/.claude/commands/bootstrap-claude-env.md ~/.claude/commands/
```
Puis, depuis **n'importe quel** répertoire Claude Code :
```
/bootstrap-claude-env
```
(sans argument, génère dans le répertoire courant).

## Ce que ce kit ne fait pas

- Il ne devine pas le contenu d'`architecture.md`/`operations.md` en scannant le code du projet cible — il pose les fondations vides, à remplir au fil de l'eau.
- Il n'installe aucune dépendance de langage, aucun linter, aucun CI. C'est un scaffold de *documentation et de méthode*, pas de code.
- Il n'a pas (encore) de mécanisme pour rétro-propager une amélioration de template vers un projet déjà bootstrapé. Si tu améliores `docs/workflow.md.tpl` ici après avoir déjà généré 3 projets, la mise à jour de ces 3 projets reste manuelle. Voir [`ADAPTING.md`](ADAPTING.md).

## Origine

Ce kit généralise le système documentaire construit sur [Holoon](https://git.andraax.com/andraax) (gouvernance organisationnelle, Angular + ASP.NET Core). Le contenu Holoon-spécifique (Holacracy, i18n multi-locales, tooling dotnet/WSL, changelog produit) n'est pas repris — seul le *pattern* (ADR/plan/backlog, persistence strategy, hooks mémoire) est extrait.
