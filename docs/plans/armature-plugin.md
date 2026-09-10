---
status: implemented
created: 2026-07-04
settled: 2026-07-06
related-adr: 0004
---

# Plan — Armature comme plugin `armature` (compagnon de l'ADR 0004)

Compagnon de [l'ADR 0004](../adr/0004-plugin-armature.md). Capture *comment* Armature devient un plugin Claude Code distribuable, *quelles* alternatives ont été explorées, et *ce qui* reste ouvert.

## Reformulation du problème

Faire passer Armature du modèle « **copie de fichiers** dans chaque projet + `KIT_ROOT` résolu par chemin en dur » au modèle « **plugin installé une fois**, commandes namespacées `/armature:…`, templates lus depuis l'installation ». Contraintes : les commandes doivent marcher dans tout projet (installé, pas copié) ; les templates doivent voyager avec le plugin (`${CLAUDE_PLUGIN_ROOT}/templates/<lang>/`) ; les deux seuls projets déployés (`voxtrail`, `Unfog`) doivent être rebasculés ; garder le repo dogfoodable (sa propre `docs/`).

## Forme cible

Le repo `Plasma-AndraaX/armature` = **marketplace (racine) + plugin isolé sous `plugin/`** (le plugin ne doit pas embarquer la doc de dev — cf. Lot 1) :

```
armature/                                  ← repo = marketplace + dev
├── .claude-plugin/
│   └── marketplace.json                   ← marketplace, source: ./plugin
├── plugin/                                ← LE plugin distribué (namespace /armature:)
│   ├── .claude-plugin/plugin.json         ← name: "armature"
│   ├── skills/
│   │   ├── bootstrap/SKILL.md  → /armature:bootstrap
│   │   ├── new-adr/SKILL.md               → /armature:new-adr
│   │   └── … (les autres)
│   └── templates/  en/  fr/               ← bundlés, lus via ${CLAUDE_PLUGIN_ROOT}/templates
├── README · CHANGELOG · ADAPTING
└── docs/  adr/ plans/ backlog/            ← doc dogfoodée, HORS du plugin distribué
```

Résolution `KIT_ROOT` dans les skills : **`${CLAUDE_PLUGIN_ROOT}`** remplace intégralement l'ordre actuel `$ARMATURE_HOME` → `/mnt/c/dev/armature` → demander. Flux tiers : `/plugin marketplace add Plasma-AndraaX/armature` puis `/plugin install armature@armature`, ensuite `/armature:bootstrap <chemin>`.

## Surface d'impact

### Structure du plugin
- **Nouveaux** : `.claude-plugin/marketplace.json` (racine, `source: ./plugin`) + `plugin/.claude-plugin/plugin.json` (`name: armature`, `version`). Le plugin vit **sous `plugin/`** ; la doc de dev reste à la racine, hors du plugin (Lot 1).
- **Migration** : `templates/<lang>/dot-claude/commands/*.md` → `skills/<nom>/SKILL.md` (format skill : dossier + `SKILL.md`, frontmatter `description`/`$ARGUMENTS` conservés). Ces commandes cessent d'être des *templates copiés*.

### Skill bootstrap & résolution KIT_ROOT
- `bootstrap` : Phase 1 résout `KIT_ROOT = ${CLAUDE_PLUGIN_ROOT}` et lit la langue via `${user_config.lang}` ; Phase 4 **ne copie plus** les commandes (elles vivent dans le plugin) et **n'écrit plus de tampon** (ADR 0005) — ne génère que la doc/structure, un seul profil.

### `propose`/`pull` & tampon
- **Supprimés** ([ADR 0005](../adr/0005-simplifications-post-plugin.md)) : les 2 skills et le tampon `.armature-version` disparaissent (détail dans [`post-plugin-simplification.md`](post-plugin-simplification.md)).

### Doc & outillage
- `README` (install via plugin, plus via clone), `ADAPTING`, `CLAUDE.md` (structure), `CHANGELOG`.
- `tools/lint-templates.py` : les commandes ne sont plus des templates `dot-claude/commands/` — adapter la parité/le lint aux `skills/` du plugin.

### Projets déployés
- `voxtrail`, `Unfog` : retirer leurs `.claude/commands/*` kit-owned, installer le plugin `armature`. Garder leur doc copiée.

## Lots d'implémentation

### Lot 1 — Squelette plugin + skill pilote
- `.claude-plugin/plugin.json` + `marketplace.json` ; migrer **une** commande (`new-adr`) en `skills/new-adr/SKILL.md` ; tester `claude --plugin-dir .`.
- **Critère de sortie** : `/armature:new-adr` s'invoque et fonctionne via `--plugin-dir`.

### Lot 2 — Templates via `${CLAUDE_PLUGIN_ROOT}` + bootstrap
- Réécrire la résolution `KIT_ROOT` de `bootstrap` sur `${CLAUDE_PLUGIN_ROOT}` (supprimer `/mnt/c/dev/armature` + `$ARMATURE_HOME`) ; migrer le skill en `skills/`.
- **Critère de sortie** : `/armature:bootstrap` génère un projet en lisant les templates bundlés, zéro chemin en dur.

### Lot 3 — Migrer les commandes restantes en skills
- Migrer en `skills/` les commandes conservées (`new-adr`, `capture-lessons`, `review-backlog`, `dashboard`, `coding-standards`, `changelog-capture`, `changelog-draft` — `propose`/`pull` supprimées, cf. ADR 0005) ; langue du contenu via `${user_config.lang}`.
- **Critère de sortie** : tous les `/armature:…` conservés fonctionnent.

### Lot 4 — Nettoyage post-plugin (ADR 0005)
- Voir le plan compagnon [`post-plugin-simplification.md`](post-plugin-simplification.md) : aplatir le profil, supprimer `propose`/`pull` + tampon. Mené conjointement à ce chantier.
- **Critère de sortie** : plus de marqueurs de profil, ni de skills de sync, ni de tampon ; lint vert.

### Lot 5 — Distribution + re-migration voxtrail/Unfog
- Publier/valider le marketplace (`claude plugin validate`) ; documenter l'install ; basculer `voxtrail` et `Unfog` sur le plugin.
- **Critère de sortie** : install tierce vérifiée sur une machine sans le repo ; les 2 projets basculés, leurs commandes copiées retirées.

### Lot 6 (gated future) — Marketplace communautaire
- Soumettre `armature` à `anthropics/claude-plugins-community`. **Déclencheur** : maturité + volonté de diffusion publique. Non bloquant.

## Alternatives considérées (plus détaillé que l'ADR)

### α — Préfixe tiret `/armature-<nom>`, modèle de copie conservé
Écartée : donne `-` pas `:`, et surtout ne résout ni la distribution tierce ni le chemin en dur — deux gains majeurs du plugin. Ne répond pas au besoin « utilisable partout, par d'autres ».

### β — Deux artefacts séparés (un plugin *commandes* + le kit *templates* restant cloné)
Écartée pour l'instant : garde le clone et le chemin en dur pour les templates. Bundler les templates dans le plugin (`${CLAUDE_PLUGIN_ROOT}`) est plus simple et supprime la dette d'un coup.

## Questions ouvertes

- ~~**Q1 — Profils Full/Minimal**~~ : résolu ([ADR 0005](../adr/0005-simplifications-post-plugin.md)) — **profil unique (Full)** ; plus de filtrage par profil, toutes les commandes sont présentes.
- ~~**Q2 — Sort de `/propose-kit-improvement` & `/pull-kit-updates`**~~ : résolu ([ADR 0005](../adr/0005-simplifications-post-plugin.md)) — **supprimés**. Commandes mises à jour via `/plugin update` ; docs trop personnalisées pour un merge ; amélioration via PR directe sur le repo.
- ~~**Q3 — Tampon `.armature-version`**~~ : résolu ([ADR 0005](../adr/0005-simplifications-post-plugin.md)) — **supprimé**. Plus de baseline de diff (propose/pull partis) ; la langue vient de `${user_config.lang}`, plus besoin de la tracer par projet.
- ~~**Q4 — `skills/` vs `commands/`**~~ : résolu (Lot 1) — format `skills/<nom>/SKILL.md` retenu ; `claude plugin validate --strict` vert avec frontmatter `description` + `argument-hint` + `disable-model-invocation`.
- ~~**Q5 — Langue / parité `en`/`fr`**~~ : résolu — **un seul jeu de skills** (instructions en anglais), templates bilingues bundlés, langue du **contenu généré** pilotée par `${user_config.lang}` (choisie à l'install via `userConfig`). Pas de double jeu de skills.
- **Q6 — Distribution** : marketplace auto-hébergé (le repo) d'abord, communautaire (Lot 6) plus tard.

## Journal de décisions

- **2026-07-04** — Architecture plugin retenue (ADR 0004) après vérification doc : le namespace `:` n'existe que via plugin ; `${CLAUDE_PLUGIN_ROOT}` bundle les templates et supprime le chemin en dur. Namespace choisi : `armature`.
- **2026-07-04** — Simplifications actées ([ADR 0005](../adr/0005-simplifications-post-plugin.md)) : profil unique (Full), suppression de `propose`/`pull` et du tampon, langue via `${user_config.lang}`. Résout Q1/Q2/Q3/Q5.
- **2026-07-04** — Lot 1 livré : squelette plugin **sous `plugin/`** (isolé de la doc de dev), `marketplace.json` racine → `source: ./plugin`, pilote `new-adr` → `/armature:new-adr`. `claude plugin validate --strict` vert (plugin + marketplace). Structure sous-dossier retenue après que le validateur a signalé le `CLAUDE.md` de dev embarqué en structure « à la racine ».

- **2026-09-10** — Plan **clôturé rétroactivement** (`implemented`, `settled: 2026-07-06`). Les lots 2 à 5 étaient livrés depuis la 0.5.0 sans que les cases soient cochées ni le statut fermé ; le plan ressortait donc en `in-progress` sur le tableau de bord et à chaque `/armature:review-backlog`. Fermeture après vérification lot par lot des critères de sortie, pas sur mémoire. Le **Lot 6** (marketplace communautaire) reste *gated future* — il n'a jamais fait partie du périmètre livrable.

## Prochaines actions

- [x] Lot 1 — squelette plugin (sous `plugin/`) + pilote `new-adr` ; `validate --strict` vert. Reste : test d'invocation *live* (`claude --plugin-dir .`) côté utilisateur.
- [x] Lot 2 — `${CLAUDE_PLUGIN_ROOT}` dans bootstrap + migration du skill. Vérifié le 2026-09-10 : plus aucun `$ARMATURE_HOME` ni `/mnt/c/dev/armature` sous `plugin/`.
- [x] Q1/Q2/Q3/Q5 tranchées (ADR 0005 + `${user_config.lang}`) ; reste Q4 (`skills/` format) à vérifier au Lot 1.
- [x] Lot 5 — publier + re-migrer voxtrail/Unfog. Livré avec la [0.5.0](../../CHANGELOG.md) (2026-07-06). **Réserve** : le sous-critère « install tierce vérifiée sur une machine sans le repo » n'a jamais été exercé — versé au backlog (§ *Action manuelle requise*) plutôt que laissé bloquer le lot.
