# Trouvailles du premier run réel des 3 skills (2026-07-01/02)

**Triage fait le 2026-07-02** : 9 des 10 frictions corrigées directement (voir le statut par item ci-dessous et `CHANGELOG.md` § Fixed/Added [Unreleased]). Seul l'item 8 reste volontairement non corrigé (jugé correct de le laisser au jugement au cas par cas).

> **Deuxième vague — runs réels sur MapMeJDR (2026-07-02).** Deux nouveaux runs de `/bootstrap-claude-env` sur un vrai projet (MapMeJDR, web-app JDR fog-of-war), d'abord en **Minimal** puis en upgrade **Minimal→Full**, ont fait ressortir **3 anomalies de rendu des templates** que le premier run (voxtrail, Full) n'avait pas exercées — parce qu'elles ne se manifestent qu'en Minimal ou au croisement profil × hook. Les 3 sont corrigées ; le détail suit en fin de fichier (§ *Deuxième vague*).

Résultat du seul item vraiment bloquant de `docs/backlog/README.md` § *Action manuelle requise* : faire tourner `/bootstrap-claude-env`, `/propose-kit-improvement` et `/pull-kit-updates` pour de vrai, dans une session Claude Code fraîche, sur un vrai projet (`/mnt/c/dev/voxtrail`, pas un répertoire jetable vide — pour que la Phase 2 de bootstrap ait un vrai code à analyser).

Méthodologie : chaque skill a été exécuté par un agent **frais** (zéro contexte préalable du kit), lisant le fichier `.md` du skill et suivant ses instructions à la lettre — l'équivalent le plus proche possible d'une vraie invocation `/commande`, `AskUserQuestion` n'étant disponible ni en session headless (`claude -p`) ni pour un subagent lancé via l'outil `Agent` (confirmé empiriquement dans les 3 runs — un repli texte a été utilisé à chaque fois, sans bloquer). Les 3 runs ont réellement écrit/committé (bootstrap + propose ont produit des commits vérifiés sur disque, pas seulement rapportés).

## Résultat global

Les 3 skills fonctionnent : bootstrap a produit un projet cohérent (profil Full, langue fr, plus une migration de contenu pré-existant demandée en sus du texte du skill), propose a correctement identifié 1 seul hunk généralisable sur 21 candidats et écarté le reste, pull a correctement détecté un vrai cas d'arbitrage à 3 voies (provoqué exprès) sans fusionner silencieusement. Aucun des 3 n'a produit de résultat incorrect — mais suivre leur texte à la lettre a exigé, à plusieurs reprises, de sortir du périmètre déclaré ou de deviner une convention non écrite. Ce qui suit est cette liste, dédupliquée.

## Frictions trouvées (par ordre de gravité)

### 1. ✅ Corrigé — Convention de mapping `.tpl` non documentée (touche `propose-kit-improvement.md` ET `pull-kit-updates.md`)

Les deux skills disent de récupérer la baseline via `git -C KIT_ROOT show <sha>:templates/<lang>/<chemin-mappé>`, en « rajoutant le suffixe `.tpl` pour les fichiers qui en avaient un » — sans dire lesquels. Dans les faits : `CLAUDE.md`, `docs/README.md`, `docs/persistence-strategy.md`, `docs/workflow.md` → `.tpl` ; mais `claude.sh`, `.gitignore`, `.env.claude.example`, `docs/adr/template.md`, `docs/plans/template.md`, tous les `dot-claude/commands/*.md`, `tools/session-end-capture.sh` → **pas** de `.tpl`. Un exécutant frais n'a aucun moyen de le savoir sans explorer `KIT_ROOT` en premier, étape non prescrite par le texte.

**Fait** : règle documentée dans `CONTRIBUTING.md` § *Which files get a `.tpl` suffix*, les deux skills y renvoient désormais au lieu de la redire.

### 2. ✅ Corrigé — Le bloc `SessionEnd` de `.claude/settings.json` n'a pas de baseline `.tpl` statique (touche les 2 mêmes skills)

Le hook `SessionEnd` est listé comme candidat, mais il n'existe dans aucun fichier `.tpl` — il est assemblé dynamiquement par la prose de `bootstrap-claude-env.md` (§ Phase 4, *"Assembling `.claude/settings.json`"*), qui n'est elle-même pas un fichier candidat. Une exécution mécanique de la recette « un chemin = un `git show` » produit un faux positif (diff fantôme) sur ce sous-candidat précis, dans les deux skills miroirs.

**Fait** : exception documentée explicitement dans les deux skills (pas de nouveau `.tpl` matérialisé — jugé disproportionné pour ce gain, la documentation suffit).

### 3. ✅ Corrigé — Phase 0 de `bootstrap-claude-env.md` : le "diff per-file" est demandé avant que Phase 4 ait rien généré

Ordre chronologiquement impossible tel qu'écrit (« montre un diff de ce qui changerait par fichier » à la Phase 0, alors que le contenu candidat n'existe qu'après la Phase 4). Contournement appliqué par l'agent de test : générer d'abord (Phases 1-4), puis montrer le diff juste avant le commit (Phase 5) — mais c'est une interprétation, pas ce que le texte dit.

**Fait** : Phase 0 précise maintenant explicitement que le diff vient après génération (Phases 1-4), juste avant le commit Phase 5 ; Phase 5 le rappelle.

### 4. ✅ Corrigé — Phase 2 (découverte plugins/MCP) de `bootstrap-claude-env.md` dépend d'un choix (profil) décidé seulement en Phase 3

Référence en avant dans l'ordre des phases — pas bloquant en pratique (l'agent a juste posé la question plus tôt), mais l'ordre documenté ne correspond pas à l'ordre d'exécution réel nécessaire.

**Fait** : la phrase d'intro de la découverte plugin/MCP dit maintenant explicitement de poser la question Profil de la Phase 3 en premier si besoin, puis de revenir avant de présenter le reste de la Phase 3.

### 5. ✅ Corrigé — `bootstrap-claude-env.md` Phase 4, ligne sur `.claude/settings.json` : *"mirror the shape used in this kit's own `.claude/settings.json`"*

Vérifié : `KIT_ROOT/.claude/settings.json` ne contient **aucune** clé `enabledPlugins` à imiter. La ligne réfère à une forme qui n'existe pas dans le fichier qu'elle cite comme référence.

**Fait** : la ligne décrit maintenant la forme directement (`"enabledPlugins": {"plugin-name@marketplace": true}`) sans pointer vers le `.claude/settings.json` du kit lui-même.

### 6. ✅ Corrigé — `docs/claude-code-tooling.md.tpl` référence conditionnellement `/bootstrap-claude-env`, mais ce fichier n'est jamais copié dans un projet bootstrapé

La branche "si conservé" du marqueur n'a jamais d'occasion d'être vraie avec le mapping de fichiers tel que décrit en Phase 4 — instruction morte.

**Fait** : ligne retirée de la table (fr + en) — `/bootstrap-claude-env` n'est de toute façon jamais copié dans un projet bootstrapé.

### 7. ✅ Corrigé — `.gitignore` : recouvrement de pattern non anticipé par la Phase 4 de bootstrap

Un `.gitignore` pré-existant avec un pattern large (`.env.*`) peut masquer silencieusement `.env.claude.example` que le skill veut committé. Phase 4 ne vérifie que les doublons d'entrées littérales, pas les recouvrements de pattern plus larges déjà présents. Contourné par `git add -f` lors du test.

**Fait** : Phase 4 vérifie maintenant explicitement les recouvrements de pattern plus larges (pas seulement les doublons littéraux) et Phase 5 utilise `git add -f` si un fichier voulu suivi serait sinon exclu.

### 8. Phase 0 de bootstrap ne couvre que la collision de *nom* (`CLAUDE.md`), pas le recouvrement *conceptuel*

Un projet peut avoir un `docs/BACKLOG.md`/`IMPLEMENTATION.md`/`decision-record-*.md` pré-existants qui recouvrent conceptuellement ce que le kit génère sous d'autres noms (`docs/backlog/`, `docs/plans/`, `docs/adr/`). Géré ici uniquement parce que le test l'a signalé explicitement et que l'utilisateur a tranché en direct (migration demandée en sus du texte du skill). Pas un bug à proprement parler — plutôt un cas non couvert, probablement correct de laisser au jugement au cas par cas plutôt que d'ajouter une heuristique.

### 9. ✅ Corrigé — Granularité de classification (Phase 4 de `propose-kit-improvement.md`) et granularité de "recouvrement" (Phase 3 de `pull-kit-updates.md`) non définies

Un hunk `diff -u` peut mélanger plusieurs changements logiquement distincts ; le texte ne dit pas s'il faut classifier/juger le recouvrement au grain ligne, hunk, mot ou caractère. Dans le cas d'arbitrage testé (`whats-left.md`), le recouvrement était réel au grain ligne (le grain natif de `diff`/git) mais pas au grain mot — l'agent a choisi prudemment de traiter ça comme un recouvrement réel plutôt que de fusionner silencieusement, mais c'est une décision d'exécutant, pas une règle du skill. Avec un exécutant moins prudent, ce sous-spécification pourrait produire une fusion auto-appliquée sur un vrai conflit sémantique.

**Fait** : `propose-kit-improvement.md` Phase 4 dit maintenant explicitement de sous-découper un hunk qui mélange plusieurs changements avant classification ; `pull-kit-updates.md` Phase 3 définit maintenant le recouvrement au grain ligne explicitement (le grain natif de `diff`/git), même si un merge mot-à-mot serait possible.

### 10. ✅ Corrigé — Profil de bootstrap (Full/Minimal, changelog on/off) non tracé dans `.claude-project-kit-version`

Le fichier ne stocke que `sha=`/`lang=`. Les deux skills miroirs doivent redéduire le profil de la présence/absence de fichiers — ambiguïté silencieuse entre "profil Minimal choisi au bootstrap" et "profil Full choisi puis fichiers supprimés depuis à la main".

**Fait** : `profile=full|minimal` et `changelog=yes|no` ajoutés au tampon (Phase 4 de bootstrap). Les deux skills miroirs les lisent en Phase 1 et retombent sur l'ancienne inférence par présence de fichiers si absents (tampons pré-existants comme celui de `voxtrail`, non re-tamponné rétroactivement). Voir `docs/backlog/versioning-and-retro-propagation.md` § *Tampon étendu à profile/changelog*.

## Point méthodologique (pas un bug du kit, mais à garder en tête)

Le classifieur de sécurité de l'environnement d'exécution a — à raison — bloqué plusieurs tentatives d'un agent de test d'appliquer des actions irréversibles/de configuration persistante (écraser `CLAUDE.md`, supprimer des fichiers pré-existants, écrire `.claude/settings.json`) sur la seule base d'un consentement utilisateur **relayé par un coordinateur**, plutôt que confirmé directement. Ce n'est pas quelque chose que `/bootstrap-claude-env`/`/propose-kit-improvement`/`/pull-kit-updates` peuvent corriger eux-mêmes — mais si ces skills sont un jour testés ou déployés dans un contexte multi-agent (CI, orchestration), il faut prévoir que les étapes qui écrivent réellement (Phase 5/6/7 selon le skill) doivent être exécutées par l'agent qui a une ligne directe et vérifiable avec l'utilisateur, pas déléguées à un sous-agent sur la foi d'un rapport.

## Ce qui a été validé, concrètement

- `voxtrail` bootstrapé en Full/fr : commits réels dans son historique git (`d2adb65`, `9778337`, `89497b4`, `f7a1ca2`, `4a12d77`, `9e871f1`).
- `/propose-kit-improvement` a produit un vrai fix accepté et appliqué dans le kit : voir commit `ef79703` sur la branche `propose/claude-sh-path-check` (`claude.sh`, `en`+`fr`, gardé en local, pas poussé).
- `/pull-kit-updates` a détecté un vrai arbitrage 3 voies provoqué exprès (`.claude/commands/whats-left.md`), présenté BASE/MIEN/NOUVEAU + un brouillon fusionné, et n'a rien écrit avant confirmation directe — résolu en "fusionner", tampon de version avancé vers `7e7d701`.

## Deuxième vague — anomalies de rendu (MapMeJDR, 2026-07-02)

Trois anomalies de rendu des templates, ressorties de deux runs réels de `/bootstrap-claude-env` sur MapMeJDR (Minimal, puis upgrade Minimal→Full). Elles ne se manifestent qu'en Minimal ou au croisement profil × hook — d'où leur invisibilité au premier run (voxtrail, Full). Toutes **corrigées le 2026-07-02** (cf. `CHANGELOG.md` § [Unreleased]).

### A1 ✅ Corrigé — paragraphe du hook mémoire gaté sur le mauvais critère (fonctionnel, le plus grave)

Dans `persistence-strategy.md.tpl`, le paragraphe interdisant la mémoire privée était enveloppé de `FULL-ONLY`. Or le hook mémoire est activable dans **les deux** profils. En Minimal + hook activé, le rendu supprimait le paragraphe — et le doc vers lequel le message d'erreur du hook renvoie devenait muet sur la règle.

**Fait** : introduction d'un axe conditionnel propre — marqueur `MEMORYHOOK-ONLY`, gaté purement par la question hook de la Phase 3 (indépendant de Full/Minimal, exactement comme `CHANGELOG-ONLY`). Répercuté dans `lint-templates.py` (`ALL_TAGS` + combos memoryhook), `bootstrap-claude-env.md` (Phase 3/4 + champ `memoryhook=yes|no` du version stamp), et `/propose-kit-improvement`/`/pull-kit-updates` (fallback tolérant : si le champ est absent, inférer de la présence du hook `PreToolUse` dans `.claude/settings.json`). Approche choisie *(option b de l'énoncé)* plutôt que l'inconditionnel : c'est la seule cohérente avec le précédent `CHANGELOG-ONLY` déjà en place, et correcte sans compromis de formulation.

### A2 ✅ Corrigé — liens cliquables vers des docs non générés (fonctionnel)

- `persistence-strategy.md.tpl` : le lien `[…](lessons-domain.md)` (ligne « Règle métier ») → dé-lié en code span `` `docs/lessons-domain.md` `` + mention « généré seulement si domaine métier riche ».
- `README.md.tpl` : les lignes de table `adr/` et `plans/` → enveloppées `FULL-ONLY` (elles laissaient deux liens morts en Minimal) ; la ligne de table `lessons-domain.md` → dé-liée (elle ne peut pas être retirée seule du bloc groupé, et le fichier n'existe qu'en domaine riche).
- **Bonus trouvé par le nouveau check de liens morts** : dans `README.md.tpl` § « Conventions de rédaction », le lien `[…](adr/template.md)` (et les puces ADR/Plans + toute la section « Références croisées », qui ne parlent que d'ADR/plans) → gatés `FULL-ONLY`. Non listé dans l'énoncé, révélé par le durcissement.

### A3 ✅ Corrigé — artefacts du strip des marqueurs (cosmétique)

`strip_markers` traitait les marqueurs de façon asymétrique : un marqueur actif en tête de ligne de tableau (`<!-- FULL-ONLY --> | cell |`) laissait un espace résiduel en tête (` | cell |`). Et sur `persistence-strategy.md.tpl`, un commentaire-note interne (`<!-- paragraphe du hook… -->`) accolé au marqueur fuyait dans la doc livrée.

**Fait** : strip symétrique (le marqueur qui ouvre/ferme une ligne emporte son espace adjacent ; un marqueur en milieu de prose garde ses espaces) ; commentaire interne supprimé ; règle « retire le marqueur **et** l'espace adjacent » répercutée dans `bootstrap-claude-env.md` (Phase 4).

### Durcissement du lint (pourquoi il ne les avait pas vues)

`lint-templates.py` vérifiait l'équilibre des marqueurs, la parité en/fr et les lignes vides dans les tableaux — pas les liens relatifs cassés, ni les espaces en tête, ni les commentaires parasites. Ajouté : **(a)** un check de liens relatifs « vers un fichier du template non généré dans ce profil » (ignore les refs externes/kit comme `ADAPTING.md`) — il aurait attrapé A2 et a effectivement trouvé le lien bonus ci-dessus ; **(b)** un check d'espace en tête de ligne de tableau après rendu — il aurait attrapé A3. Le lint couvre désormais toutes les combinaisons profil × changelog × memoryhook.
