# Guide d'adaptation

Check-list de ce qu'il faut personnaliser après (ou pendant) un `/bootstrap-claude-env`, selon le contexte du projet cible. Le skill pose les questions de base (nom, stack, solo/équipe, profil) mais ne peut pas tout déduire — cette page couvre le reste.

## Profil Full vs Minimal

| Signal | Profil conseillé |
|---|---|
| Prototype, POC, projet perso à durée de vie incertaine | **Minimal** |
| Projet avec au moins un autre contributeur (humain ou toi-sur-un-autre-poste) | **Full** |
| Tu prévois de revenir dessus dans plusieurs mois et veux te souvenir du "pourquoi" | **Full** |
| Le projet va accumuler des décisions structurantes (choix d'archi, migrations, tradeoffs produit) | **Full** |

Le passage Minimal → Full n'est pas automatisé : relance `/bootstrap-claude-env` sur le même répertoire, le skill détecte les fichiers déjà présents et ne régénère que ce qui manque (voir § *Écraser vs compléter* dans le skill).

## Langue des templates

Indépendant du profil Full/Minimal : `templates/en/` et `templates/fr/` ont la même structure et la même mécanique (marqueurs de profil, placeholders, script dashboard) — seule la prose diffère. Le skill demande la langue en Phase 1.

Une correction de fond (pas juste un mot) apportée à un fichier d'une langue — par exemple le fix du bug de tableau Markdown cassé par les marqueurs `FULL-ONLY` — doit être reportée manuellement dans l'autre langue : ce n'est **pas** automatique. Vérifier les deux dossiers `templates/<lang>/` restent en parité structurelle (mêmes fichiers, mêmes lignes marquées) après toute évolution du skill ou d'un gabarit.

## Solo vs équipe

- **Solo** : `docs/prefs/<login>.md` a moins de valeur (tu n'as personne d'autre à qui rendre tes préférences visibles) — tu peux le garder pour toi-futur sur un autre poste, ou l'omettre.
- **Équipe** : committer `docs/prefs/<login>.md` dès le premier contributeur. Le hook mémoire (si activé) prend tout son sens ici — sans lui, chaque dev accumule sa propre mémoire privée invisible des autres.

## Adapter `docs/operations.md` à ta stack

Le template généré est un squelette de sections (Setup / Build / Run / Test / Deploy) sans contenu — à remplir toi-même. Quelques repères selon le langage :

| Stack | Sections à détailler en priorité |
|---|---|
| Node/TypeScript (frontend ou backend) | gestionnaire de paquets (npm/pnpm/yarn), scripts `package.json`, variables d'env, proxy dev si front+back séparés |
| Python | venv/poetry/uv, migrations si ORM, variables d'env, commande de lint/format |
| .NET | solution/projets, `dotnet build`/`restore` (attention aux pièges cross-OS type WSL — voir `lessons-technical.md` une fois qu'ils surgissent), migrations EF si applicable |
| Go | modules, build tags, migrations si applicable |
| Infra / IaC | outil (Terraform/Pulumi/etc.), workspaces, secrets management |

## Domaine métier riche ou pas ?

`docs/lessons-domain.md` n'a de sens que si le projet encode des règles métier non triviales (comme Holacracy sur Holoon). Un CRUD interne ou un outil technique pur (CLI, lib) n'en a généralement pas besoin — dans ce cas, ne génère pas ce fichier (le profil Minimal l'omet déjà par défaut ; en Full, tu peux le supprimer après coup si tu réalises qu'il ne sert à rien).

## Hook mémoire privée : fortement recommandé, même si le skill le demande quand même

Le hook (`PreToolUse` sur `Write`/`Edit` visant `*/memory/*`) impose que tout ce qui doit durer passe par le repo versionné plutôt que la mémoire privée Claude. Ce n'est **pas présenté comme un choix neutre** dans le skill de bootstrap — la mémoire privée jamais versionnée est une manière facile de perdre silencieusement des décisions, de dériver de ce que l'équipe a réellement décidé, ou de laisser fuir des suppositions d'un projet à l'autre sans trace auditable. Le coût de ce problème grandit avec le temps et se découvre presque toujours trop tard.

Le skill pose quand même la question (l'utilisateur reste décisionnaire), mais argumente pour le *oui* par défaut, y compris en solo — la mémoire privée sur une seule machine reste plus fragile (pas de review, pas de portabilité, pas d'historique) même sans co-équipier à qui rendre les choses visibles.

## Backlog : dans ce repo ou dans un outil externe ?

Le skill demande explicitement en Phase 3 où vit le backlog. Si l'équipe utilise déjà Jira/Trello/Notion/Linear/GitHub Issues, ne génère **pas** `docs/backlog/` — imposer un second système concurrent au premier crée de la confusion et personne ne le maintient. Dans ce cas, `docs/persistence-strategy.md` et les autres références à `docs/backlog/` sont ajustées pour nommer l'outil externe à la place.

Cas particulier — **TODOs déjà présents dans le code existant** : si Phase 2 en détecte un nombre non-trivial, le skill propose (jamais automatiquement) de les trier en items de backlog au moment du bootstrap. En dehors de ce geste de migration ponctuel, les `TODO`/`FIXME` du code restent délibérément exclus comme source de backlog continue (cf. `whats-left.md`) — trop bruyants, jamais triés.

## Changelog utilisateur

Le kit fournit un module générique (`docs/changelog/` + `/changelog-capture` + `/changelog-draft`, profil Full uniquement, question dédiée en Phase 3) : capture d'une note pendant que le contexte est frais, rédaction formatée au moment de la release. Ce que ce module **ne fournit pas**, volontairement :
- la **traduction multi-langue** des notes (Holoon en a besoin, la plupart des projets non) ;
- la **publication** effective (site de doc, in-app, mailing list) — spécifique à chaque produit ;
- un format de sortie imposé — adapte `/changelog-draft` à ta convention (Keep a Changelog, GitHub Releases, autre).

Si tu as besoin de traduction multi-locale, inspire-toi de la doctrine Holoon (Markdown versionné dans le repo plutôt qu'un CMS externe) et étends `/changelog-draft` toi-même.

## Plugins / MCP suggérés au bootstrap

Le skill ne se contente pas de poser la structure documentaire — en profil Full, il délègue à l'agent `claude-code-guide` (jamais à une recherche web ouverte) pour identifier les plugins Anthropic-verified ou les serveurs MCP officiels pertinents pour le stack détecté. `docs/claude-code-tooling.md` **ne part jamais vide** : il reflète toujours au minimum ce qui a été jugé pertinent, même si tout est marqué `suggested`.

Deux gestes distincts, pas un choix exclusif :
- **Consigner** — toujours fait, dans la table "Plugins / serveurs MCP" du fichier tooling.
- **Activer** — une question séparée, par plugin : le skill propose d'ajouter l'entrée dans `enabledPlugins` de `.claude/settings.json` (ou de donner la commande de config MCP) *maintenant*, plutôt que de laisser un outil documenté-mais-jamais-configuré. Si l'activation nécessite un secret, le skill ne le fournit jamais lui-même — il donne la commande exacte et laisse l'utilisateur la lancer (même logique que pour le token Forgejo lors du déploiement de ce kit).

## `claude.sh` — lancer Claude avec les bonnes variables d'environnement

`claude.sh` (racine du projet cible) charge `.env.claude` (gitignored, jamais commité) puis lance `claude "$@"` — passe-plat complet des arguments. `.env.claude.example` est committé et documente les deux façons de renseigner une valeur : en clair, ou résolue depuis la CLI d'un gestionnaire de mots de passe (`op`, `bw`, `pass`, etc.) — puisque le fichier est `source`-é en bash, une ligne `export TOKEN=$(op read ...)` s'exécute normalement, aucune intégration spécifique par outil n'est nécessaire.

**Limite connue** : c'est un script bash. Sur Windows natif (hors WSL), il ne fonctionne pas tel quel — un équivalent `.ps1` est une extension possible, pas fournie en v1.

## Capture en fin de session — message ou auto

Un hook `SessionEnd` (profil Full uniquement) peut prévenir quand une session se termine avec du travail non capturé. Deux modes, choisis à la Phase 3 du bootstrap :

- **`message`** *(recommandé par défaut)* — affiche un rappel visible (mentionnant `claude.sh --continue`) si l'arbre git est sale et que rien dans le transcript ne montre que `/capture-lessons`/`/changelog-capture` ont déjà tourné. Coût nul si rien à signaler, humain toujours dans la boucle avant toute écriture.
- **`auto`** — lance un `claude -p` headless détaché (`tools/session-end-capture.sh auto`) qui lit la fin du transcript, applique **les mêmes filtres** que `.claude/commands/capture-lessons.md`/`changelog-capture.md` (il les lit lui-même plutôt que de dupliquer la doctrine), et écrit directement dans les fichiers concernés. Il ne commite **jamais** — la relecture humaine reste obligatoire, juste déplacée à la session suivante plutôt que supprimée. Outils autorisés restreints à `Read Edit Write Glob Grep` (pas de Bash), garde anti-récursion par variable d'environnement (`CLAUDE_HOOK_SPAWNED`), transcript capé à 4 Mo.

Le gate (arbre dirty + rien capturé) est une heuristique, pas une garantie — même posture "best-effort" que le reste du kit. Le pattern est adapté d'un hook personnel validé en conditions réelles ; durci pour un kit public (pas de Bash dans les outils headless, pas de logique spécifique à un environnement).

## Conventions de code hétérogènes

`docs/coding-standards.md` (présent dans les deux profils, comme `architecture.md`/`operations.md`) est l'endroit où vit le style de code réellement observé — pas une simple ligne dans `CLAUDE.md`, précisément parce qu'un codebase peut être hétérogène (plusieurs langages, dérive entre sous-projets, legacy vs code récent). Le skill l'écrit à partir de Phase 2 : un échantillonnage de fichiers réels, pas seulement la config du linter.

Si Phase 2 détecte un vrai conflit — la config déclare une convention mais une part significative du code ne la suit pas — elle ne tranche **pas** silencieusement. Elle te pose la question en Phase 3 : documenter la convention déclarée comme cible, documenter la convention dominante observée comme convention de fait, ou trancher toi-même. La réponse va dans la section « Déclaré vs observé » du fichier, datée. Si le codebase est homogène ou s'il n'y a pas de code existant, cette question ne se pose simplement pas.

## Limite connue : pas de rétro-propagation

Si tu améliores un `.tpl` dans `claude-project-kit` après avoir déjà bootstrapé plusieurs projets, ces projets ne se mettent pas à jour automatiquement. Pour l'instant :
1. Diff manuel entre le fichier généré chez toi et le template mis à jour ici.
2. Applique la partie pertinente à la main.

Un mécanisme de sync automatique (genre `cookiecutter --replay` ou un script de diff templates↔instances) est une amélioration future possible de ce kit, pas construite en v1.
