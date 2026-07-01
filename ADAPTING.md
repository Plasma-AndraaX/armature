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

## Hook mémoire privée : l'activer ou pas ?

Le hook (`PreToolUse` sur `Write`/`Edit` visant `*/memory/*`) impose que tout ce qui doit durer passe par le repo versionné plutôt que la mémoire privée Claude. Pertinent si :
- plusieurs contributeurs (humains ou instances Claude sur des machines différentes) doivent voir les mêmes décisions,
- tu veux que `git log docs/` fasse office d'historique des décisions "apprises" par l'agent.

Moins utile en solo sur une seule machine, où la mémoire privée peut suffire — mais elle reste plus fragile (pas de review, pas de portabilité).

## Changelog utilisateur (non fourni par ce kit)

Holoon a un processus de changelog produit (notes de release traduites, publiées) documenté dans `docs/changelog/`. C'est un choix produit spécifique, pas repris ici. Si ton projet a besoin d'un changelog user-facing : inspire-toi de la doctrine (Markdown versionné dans le repo plutôt qu'un CMS externe — voir l'ADR "changelog in repo" sur Holoon comme référence de raisonnement) et construis ton propre module `docs/changelog/` + skill de capture/draft.

## Limite connue : pas de rétro-propagation

Si tu améliores un `.tpl` dans `claude-project-kit` après avoir déjà bootstrapé plusieurs projets, ces projets ne se mettent pas à jour automatiquement. Pour l'instant :
1. Diff manuel entre le fichier généré chez toi et le template mis à jour ici.
2. Applique la partie pertinente à la main.

Un mécanisme de sync automatique (genre `cookiecutter --replay` ou un script de diff templates↔instances) est une amélioration future possible de ce kit, pas construite en v1.
