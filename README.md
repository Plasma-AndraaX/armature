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

## Langues

Les gabarits vivent sous `templates/<lang>/` — un dossier par langue de contenu, structure identique (même fichiers, mêmes marqueurs de profil `<!-- FULL-ONLY -->`/`<!-- MINIMAL-ONLY -->`), seul le texte change. Aujourd'hui : `templates/en/` (anglais) et `templates/fr/` (français). Le skill demande la langue au démarrage (Phase 1) — si une seule variante existe, il l'utilise sans demander.

Ajouter une langue : dupliquer `templates/en/` en `templates/<code>/` et traduire fichier par fichier, en gardant les marqueurs de profil et les clés de frontmatter YAML (`status`, `date`, `related-adr`, etc.) en anglais — seule la prose change. Pour `tools/generate-dashboard.py.tpl`, adapter aussi les regex `is_resolved`/`is_primary`/`find_subitem_of` aux conventions textuelles de la nouvelle langue (ex. le marqueur de bundle « PRIMARY » devient « PRINCIPAL » en français).

## Détection automatique du projet existant

Si le répertoire cible contient déjà du code, le skill fait un premier passage d'analyse (façon `/init` natif de Claude Code) : détection des manifests (`package.json`, `*.csproj`, `pyproject.toml`, `go.mod`, `Cargo.toml`...), du langage/framework, des scripts de build/run/test déjà déclarés, et de la structure des dossiers. Les réponses détectées pré-remplissent `CLAUDE.md`, `docs/architecture.md` et `docs/operations.md` au lieu de laisser des `TODO` vides — à confirmer/corriger, pas à prendre pour argent comptant sur un projet complexe. Sur un répertoire vide (nouveau projet net-new), cette phase est simplement sautée.

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
Le skill demande d'abord la langue des gabarits (§ Langues ci-dessus), puis pose quelques questions (nom du projet, stack, solo/équipe, profil Full/Minimal, hook mémoire oui/non), puis écrit dans le répertoire cible — pas besoin d'y être `cd`, Claude Code écrit à des chemins absolus arbitraires.

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

- La détection automatique (§ ci-dessus) est un point de départ *best-effort*, pas un audit d'architecture — sur un projet déjà complexe, elle ne remplace pas une vraie session de rédaction d'`architecture.md`. Sur un répertoire vide, tout reste en `TODO` à remplir au fil de l'eau.
- Il n'installe aucune dépendance de langage, aucun linter, aucun CI. C'est un scaffold de *documentation et de méthode*, pas de code.
- Il n'a pas (encore) de mécanisme pour rétro-propager une amélioration de template vers un projet déjà bootstrapé. Si tu améliores `docs/workflow.md.tpl` ici après avoir déjà généré 3 projets, la mise à jour de ces 3 projets reste manuelle. Voir [`ADAPTING.md`](ADAPTING.md).

## Origine

Ce kit généralise le système documentaire construit sur [Holoon](https://git.andraax.com/andraax) (gouvernance organisationnelle, Angular + ASP.NET Core). Le contenu Holoon-spécifique (Holacracy, i18n multi-locales, tooling dotnet/WSL, changelog produit) n'est pas repris — seul le *pattern* (ADR/plan/backlog, persistence strategy, hooks mémoire) est extrait.
