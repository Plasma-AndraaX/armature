---
status: implemented
created: 2026-07-04
settled: 2026-07-06
related-adr: 0005
---

# Plan — Simplifications post-plugin (compagnon de l'ADR 0005)

Compagnon de [l'ADR 0005](../adr/0005-simplifications-post-plugin.md). Capture *comment* retirer du kit ce que la bascule plugin ([ADR 0004](../adr/0004-plugin-armature.md)) rend superflu. Ces deux chantiers s'implémentent **ensemble** — ce plan est le volet « nettoyage », le plan [`armature-plugin.md`](armature-plugin.md) le volet « construction ».

## Reformulation du problème

Enlever trois pans du kit : (1) l'**axe de profil** Full/Minimal (44 paires `FULL-ONLY` → inconditionnel, 4 paires `MINIMAL-ONLY` → supprimées) ; (2) la **synchronisation** projet↔kit (2 skills `propose`/`pull` × 2 langues) ; (3) le **tampon** `.armature-version` et son versioning. Contraintes : préserver les axes orthogonaux `CHANGELOG-ONLY` (20) et `MEMORYHOOK-ONLY` (8) ; garder le lint vert ; garder la parité `en`/`fr` sur ce qui reste.

## Forme cible

Après nettoyage, un projet bootstrapé reçoit **un seul jeu de doc** (ex-Full), sans marqueur de profil, sans tampon, sans skills de sync. Les seuls opt-in restants sont `changelog` et `memoryhook` (orthogonaux). Le bootstrap ne pose plus la question de profil. La rétro-propagation redevient un diff manuel documenté (`ADAPTING.md`).

## Surface d'impact

### Templates — marqueurs de profil
- **`FULL-ONLY`** : 44 paires dans 18 fichiers → retirer les marqueurs, **garder** le contenu (résolution « toujours présent »).
- **`MINIMAL-ONLY`** : 4 paires dans 6 fichiers → **supprimer** le contenu encadré.
- Conserver intacts `CHANGELOG-ONLY` / `MEMORYHOOK-ONLY`.

### Templates — skills de sync
- Supprimer `templates/{en,fr}/dot-claude/commands/propose-kit-improvement.md` et `pull-kit-updates.md` (4 fichiers). (Note : ces skills deviennent de toute façon caduques avec le plugin — cf. ADR 0004.)

### Skill bootstrap
- `bootstrap` : retirer la **question de profil** (Phase 3), retirer l'écriture du **tampon** `.armature-version` (Phase 4) et son champ `profile=`. La logique « Full/Minimal » de génération (Phase 4) devient « générer tout ».

### Lint
- `tools/lint-templates.py` : retirer l'axe profil des combinaisons vérifiées (garder `changelog` × `memoryhook`) ; retirer la connaissance des `MINIMAL_SKIP_COMMANDS` / listes de profil ; retirer toute référence au tampon.

### Doc
- `README.md` (section « deux profils » → supprimée ; install via plugin), `ADAPTING.md` (table de décision profil → supprimée ; « Limite connue » remise en avant), `CLAUDE.md`, `CHANGELOG.md`. `docs/claude-code-tooling.md.tpl` : retirer les lignes `propose`/`pull` de la table des skills.

## Lots d'implémentation

> Ces lots sont **imbriqués** avec ceux du plan plugin ([`armature-plugin.md`](armature-plugin.md)) — en pratique, exécutés dans le même mouvement.

### Lot A — Aplatir le profil
- Retirer les 44 paires `FULL-ONLY` (garder le contenu), supprimer les 4 paires `MINIMAL-ONLY`, retirer la question profil du bootstrap, retirer l'axe profil du lint.
- **Critère de sortie** : plus aucun `FULL-ONLY`/`MINIMAL-ONLY` dans `templates/` ; `lint-templates.py` vert sur les combinaisons restantes (`changelog` × `memoryhook`).

### Lot B — Supprimer la synchronisation
- Supprimer les 4 fichiers `propose`/`pull` ; retirer l'écriture du tampon (bootstrap Phase 4) et le champ `profile=` ; nettoyer toutes les références au tampon et aux 2 skills dans la doc.
- **Critère de sortie** : `rg 'propose-kit-improvement|pull-kit-updates|armature-version'` ne renvoie plus que des mentions historiques assumées (release notes datées du CHANGELOG).

### Lot C — Doc de cadrage
- `README`/`ADAPTING`/`CLAUDE`/`CHANGELOG` : retirer le vocabulaire de profil et de sync, remettre en avant la « Limite connue : pas de rétro-propagation ».
- **Critère de sortie** : la doc ne décrit plus qu'un profil unique, sans sync ni tampon.

## Alternatives considérées (plus détaillé que l'ADR)

### α — Minimal survivant comme « preset documentaire »
Écartée : même allégé, ça garde un axe conditionnel dans les templates et le lint. Le gain (un projet plus léger) ne paie plus son coût dès lors que toutes les commandes sont dans le plugin de toute façon.

### β — `propose`/`pull` recentrés sur la doc copiée
Écartée : les docs générées sont trop personnalisées par projet pour qu'un three-way merge soit fiable ou souvent voulu. La complexité de deux skills de merge ne se justifie plus.

## Questions ouvertes

- **Q1 — Ordre vs plan plugin** : Lots A/B/C avant, pendant, ou après les lots du plan plugin ? Piste : les mener **conjointement** (une seule passe de refonte), puisque les deux touchent bootstrap, lint et doc.
- **Q2 — Contenu `MINIMAL-ONLY`** : à supprimer purement (c'était la variante réduite d'un fichier) — vérifier au cas par cas qu'aucun fragment `MINIMAL-ONLY` ne portait une info absente de la version Full.

## Journal de décisions

- **2026-07-04** — Décidé (ADR 0005) : profil unique (Full), suppression de `propose`/`pull` et du tampon `.armature-version`. Déclencheur : la bascule plugin (ADR 0004) rend ces trois pans superflus. Langue de contenu via `${user_config.lang}`.

- **2026-09-10** — Plan **clôturé rétroactivement** (`implemented`, `settled: 2026-07-06`). Les trois lots étaient livrés avec la 0.5.0 mais **aucune** case n'avait jamais été cochée ; le plan comptait comme actif partout. Fermeture après vérification des trois critères de sortie sur le dépôt tel qu'il est aujourd'hui. Le seul point non refermé proprement est la garde Q2, non traçable après coup.

## Prochaines actions

- [x] Lot A — aplatir le profil (marqueurs + bootstrap + lint). Vérifié le 2026-09-10 : aucun `FULL-ONLY`/`MINIMAL-ONLY` dans `plugin/templates/` ni `plugin/skills/` (seul résidu : un commentaire d'explication dans `tools/lint-templates.py`), lint vert.
- [x] Lot B — supprimer sync (skills + tampon + refs). Vérifié le 2026-09-10 : `propose-kit-improvement`/`pull-kit-updates`/`armature-version` n'apparaissent plus que dans les notes de version datées du `CHANGELOG.md` — le critère de sortie mot pour mot.
- [x] Lot C — doc de cadrage. Vérifié le 2026-09-10 : plus aucune mention de profil ni de Minimal dans `README.md`, `ADAPTING.md`, `CLAUDE.md`.
- [x] Q2 — garde de pré-suppression, **non traçable a posteriori** : le contenu `MINIMAL-ONLY` supprimé n'est plus inspectable autrement que dans l'historique git. Aucun manque signalé depuis la 0.5.0. Clos comme tel, pas comme vérifié.
