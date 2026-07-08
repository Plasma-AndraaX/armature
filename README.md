# Armature

> *L'ossature qu'on pose dans un projet avant d'y monter la doc, les décisions et les conventions. Pas du code : l'environnement de travail avec Claude.*

**Version actuelle : [0.6.1](CHANGELOG.md#061---2026-07-08)** — voir [`CHANGELOG.md`](CHANGELOG.md) pour l'historique lisible par un humain.

Un kit pour installer, sur n'importe quel projet informatique (n'importe quel langage/stack), l'**environnement Claude** que j'utilise sur Holoon : de la doc versionnée qui fait office de mémoire durable pour l'agent, un cycle ADR ↔ plan ↔ backlog pour tracer les décisions, et une poignée de skills qui font vivre tout ça.

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
| `docs/coding-standards.md` | Conventions de style/nommage réellement en vigueur — une section par langage/module si le codebase est hétérogène. Vivant. |
| `docs/lessons-domain.md` *(optionnel)* | Règles métier non-évidentes, si le projet a un domaine riche. Append-only, daté. |
| `docs/adr/` | Décisions architecturales actées — une par fichier, numérotées, gelées une fois `accepted`. |
| `docs/plans/` | Le *comment* d'un ADR accepté — vivant tant qu'`in-progress`, gelé (renommé avec préfixe date) une fois `implemented`. |
| `docs/backlog/` *(sauf si tu utilises déjà Jira/Trello/Notion/etc. — le skill demande)* | Idées / dette / douleurs pas encore mûres pour un ADR. |
| `docs/workflow.md` | La doctrine : quand ouvrir un ADR vs un backlog item, où vont les points qui émergent en cours d'implémentation, checklist de clôture. |
| `docs/persistence-strategy.md` | La matrice "tel type d'info → tel fichier". Désactive la mémoire privée Claude (si tu choisis cette option). |
| `docs/prefs/<login>.md` | Préférences individuelles par contributeur, committées. |
| `docs/claude-code-tooling.md` | Inventaire des skills/plugins/hooks Claude utilisés sur ce projet — jamais vide : le skill y consigne les plugins/MCP Anthropic-verified pertinents pour le stack détecté, et propose de les activer un par un dans `.claude/settings.json`. |
| `docs/dashboard.html` + `tools/generate-dashboard.py` | Vue HTML générée de l'état ADR ↔ plan ↔ backlog. |
| `.claude/settings.json` | Hook optionnel qui bloque l'écriture dans la mémoire privée Claude et renvoie vers `persistence-strategy.md`. |
| Skills `/armature:new-adr`, `/armature:capture-lessons`, `/armature:review-backlog`, `/armature:dashboard` | Fournis par le plugin `armature` (invoqués `/armature:…`), pas copiés dans le projet. Font vivre le système au quotidien. |
| `claude.sh` + `.env.claude.example` + `.gitignore` | Script de lancement qui charge `.env.claude` (gitignored, jamais commité) puis lance `claude "$@"`. L'exemple documente valeur en clair ou résolution via un gestionnaire de mots de passe. Bash uniquement (pas de `.ps1` fourni). |
| `tools/session-end-capture.sh` *(sur demande)* | Hook `SessionEnd` optionnel : rappel visible (mode `message`) ou capture headless automatique sans commit (mode `auto`) quand une session se termine avec du travail non capturé. |
| `docs/changelog/` + `/armature:changelog-capture`, `/armature:changelog-draft` *(sur demande)* | Notes de release utilisateur : capture au fil de l'eau, rédaction à la release. Sans traduction multi-langue ni publication automatisée — voir `ADAPTING.md`. |

Détail de ce qu'il faut adapter selon ton contexte : [`ADAPTING.md`](ADAPTING.md).

## Langues

Les gabarits vivent sous `plugin/templates/<lang>/` — un dossier par langue de contenu, structure identique (même fichiers, mêmes marqueurs `<!-- CHANGELOG-ONLY -->`/`<!-- MEMORYHOOK-ONLY -->`), seul le texte change. Aujourd'hui : `plugin/templates/en/` (anglais) et `plugin/templates/fr/` (français). La langue du contenu généré vient de la config du plugin (`${user_config.lang}`).

Ajouter une langue : dupliquer `plugin/templates/en/` en `plugin/templates/<code>/` et traduire fichier par fichier, en gardant les marqueurs et les clés de frontmatter YAML (`status`, `date`, `related-adr`, etc.) en anglais — seule la prose change. Pour `tools/generate-dashboard.py.tpl`, adapter aussi les regex `is_resolved`/`is_primary`/`find_subitem_of` aux conventions textuelles de la nouvelle langue (ex. le marqueur de bundle « PRIMARY » devient « PRINCIPAL » en français).

## Détection automatique du projet existant

Si le répertoire cible contient déjà du code, le skill fait un premier passage d'analyse (façon `/init` natif de Claude Code) : détection des manifests (`package.json`, `*.csproj`, `pyproject.toml`, `go.mod`, `Cargo.toml`...), du langage/framework, des scripts de build/run/test déjà déclarés, et de la structure des dossiers. Les réponses détectées pré-remplissent `CLAUDE.md`, `docs/architecture.md` et `docs/operations.md` au lieu de laisser des `TODO` vides — à confirmer/corriger, pas à prendre pour argent comptant sur un projet complexe. Sur un répertoire vide (nouveau projet net-new), cette phase est simplement sautée.

## Utilisation

Armature se distribue comme **plugin Claude Code**. Une fois pour toutes, ajoute la marketplace puis installe le plugin :

```
/plugin marketplace add Plasma-AndraaX/armature
/plugin install armature@armature
```

Ensuite, depuis **n'importe quelle** session Claude Code :
```
/armature:bootstrap /chemin/absolu/vers/mon-nouveau-projet
```
(sans argument, génère dans le répertoire courant). Le skill pose quelques questions (nom du projet, stack, solo/équipe, hook mémoire oui/non), puis écrit dans le répertoire cible — pas besoin d'y être `cd`, Claude Code écrit à des chemins absolus arbitraires. La langue du contenu généré vient de la config du plugin (`${user_config.lang}`).

## Ce que ce kit ne fait pas

- La détection automatique (§ ci-dessus) est un point de départ *best-effort*, pas un audit d'architecture — sur un projet déjà complexe, elle ne remplace pas une vraie session de rédaction d'`architecture.md`. Sur un répertoire vide, tout reste en `TODO` à remplir au fil de l'eau.
- Il n'installe aucune dépendance de langage, aucun linter, aucun CI. C'est un scaffold de *documentation et de méthode*, pas de code.
- Il n'a pas (encore) de mécanisme pour rétro-propager une amélioration de template vers un projet déjà bootstrapé. Si tu améliores `docs/workflow.md.tpl` ici après avoir déjà généré 3 projets, la mise à jour de ces 3 projets reste manuelle. Voir [`ADAPTING.md`](ADAPTING.md).

## Origine

Ce kit généralise le système documentaire construit sur Holoon (gouvernance organisationnelle, Angular + ASP.NET Core). Le contenu Holoon-spécifique (Holacracy, i18n multi-locales, tooling dotnet/WSL, changelog produit) n'est pas repris — seul le *pattern* (ADR/plan/backlog, persistence strategy, hooks mémoire) est extrait.

## Auteur

[Plasma-AndraaX](https://github.com/Plasma-AndraaX). Publié sous licence [MIT](LICENSE) — cette licence couvre le kit et son outillage (`plugin/`, `tools/`, scripts), pas le contenu qu'il génère dans ton propre projet une fois bootstrapé, qui t'appartient sans condition.

Si tu forkes, améliores ou adaptes ce kit, une issue ou une PR sur le dépôt est la bienvenue — aucune obligation, juste une demande sympathique de l'auteur. Voir [`CONTRIBUTING.md`](CONTRIBUTING.md) pour comment les PR sont triées.

## Backlog du kit

Les sujets ouverts sur le kit lui-même (pas sur un projet bootstrapé) vivent dans [`docs/backlog/`](docs/backlog/README.md).
