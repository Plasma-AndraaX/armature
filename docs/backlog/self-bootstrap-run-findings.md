# Trouvailles du run de self-bootstrap (2026-09-09)

> **Contexte** — premier run end-to-end réel de `/armature:bootstrap`, appliqué au repo Armature lui-même, par un **agent frais** (aucun contexte du kit) suivant le texte du skill à la lettre dans un **worktree isolé**, avec interdiction d'écraser tout fichier existant (candidats en collision déviés vers `.bootstrap-candidate/`). Pendant du [premier run sur un projet tiers](first-real-run-findings.md) de 2026-07-01/02. Décision de lancer ce run : [`appliquer-armature-a-armature.md`](appliquer-armature-a-armature.md).
>
> **Triage fait le 2026-09-09**, le jour même :
> - **F1 corrigée** — bug de rendu **en production** (une ligne de tableau gatée soudait le tableau au bloc suivant, dans tout projet bootstrapé sans le module changelog). `strip_markers` corrigé + nouveau `check_table_run_on` dans le linter, vérifié dans les deux sens. C'est la trouvaille qui justifie à elle seule le run : le linter était vert depuis 0.4.0 parce que ses deux implémentations partageaient le défaut.
> - **F2, F3, F4, F6, F7 corrigées** dans `plugin/skills/bootstrap/SKILL.md`.
> - **F5 et F10 versées au backlog** — même racine que [`orchestrated-command-invocation.md`](orchestrated-command-invocation.md) : une commande conçue pour un humain interactif, invoquée sans canal interactif.
> - **F8 et F9 non traitées**, laissées au jugement : borner le format attendu de `{{PRIMARY_STACK}}`, et adapter la grille des agents `Explore` à un dépôt dont le contenu *est* de la documentation.
> - **F11 écartée — faux positif.** L'absence de `/armature:bootstrap` dans le tableau des skills de `claude-code-tooling.md` est **délibérée** depuis la 0.4.0 (voir [`first-real-run-findings.md`](first-real-run-findings.md) § 6 : cette commande n'est jamais copiée dans un projet bootstrapé). L'agent ne pouvait pas le savoir ; à retenir sur la lecture d'un rapport d'agent frais.

**Date** : 2026-09-09 · **Cible** : `/mnt/c/dev/Armature/.claude/worktrees/agent-a1fe7a53d578a80a2` (worktree isolé)
**Skill suivi** : `plugin/skills/bootstrap/SKILL.md` (v0.7.0, Phase 3 « récolte » incluse)
**Exécutant** : agent frais, sans contexte préalable, suivant le texte à la lettre.

Options retenues (cahier de réponses) : langue `fr` · projet `Armature` · équipe solo · backlog dans le repo · **module changelog : non** · **hook mémoire : oui** · **auto-capture de fin de session : auto** · pas de `lessons-domain.md`.

---

## 1. Ce qui a été généré

### Nouveaux fichiers (écrits à leur place normale — n'existaient pas)

```
.env.claude.example
docs/README.md
docs/architecture.md              ← enrichi Phase 5 (contenu réel, pas de TODO)
docs/claude-code-tooling.md       ← enrichi Phase 5 (hooks + skills + MCP)
docs/coding-standards.md          ← enrichi Phase 5 (conventions réellement observées)
docs/operations.md                ← enrichi Phase 5 (commandes réelles)
docs/persistence-strategy.md
docs/workflow.md
docs/prefs/README.md
docs/adr/template.md              ← voir § 4 : inadapté à ce repo
docs/plans/template.md            ← voir § 4 : inadapté à ce repo
docs/incidents/template.md        ← voir § 4 : inadapté à ce repo
tools/generate-dashboard.py       (chmod +x)
tools/session-end-capture.sh      (chmod +x)
```

### Fichier existant modifié (append non destructif, prescrit par le skill)

```
.gitignore    + « .env.claude » et « tools/session-end-capture.log »
```

Vérifié conformément à la Phase 5 : aucun motif préexistant plus large (pas de `.env.*`) ne
« mange » `.env.claude.example` ou `claude.sh` → pas de `git add -f` requis.

### Candidats en collision (fichier déjà existant → écrit sous `.bootstrap-candidate/`)

| Chemin cible | Existant | Candidat | En quoi le candidat diffère |
|---|---|---|---|
| `CLAUDE.md` | 33 l. | 54 l. | Index générique « question → doc ». Perd tout le contenu réel : « What this repo is », « Structure », le paragraphe « Where things stand » (état du projet, 8 ADR), et les conventions de travail (marqueurs, dogfooding, parité en/fr). J'ai rempli sa section *Build & Commandes* avec les vraies commandes. |
| `claude.sh` | 12 l. | 53 l. | **Deux scripts sans rapport.** L'existant = variante dogfooding (`claude --plugin-dir ./plugin`). Le candidat = passe-plat qui source `.env.claude`. Écrasement refusé (voir friction F2). |
| `.claude/settings.json` | 5 l. | 26 l. | Existant : `permissions.allow: []` seul. Candidat : idem + hook `PreToolUse` de blocage mémoire + hook `SessionEnd` d'auto-capture. Assemblé à la main comme le prescrit la Phase 5 (pas de gabarit statique combiné). Ajout non destructif possible. |
| `docs/lessons-technical.md` | 27 l., 2 leçons réelles | 21 l. | Gabarit vide avec entrée « [Template] ». Strictement régressif. |
| `docs/adr/README.md` | 18 l., index de 8 ADR | 11 l. | Index vide. Régressif. |
| `docs/plans/README.md` | 16 l. | 11 l. | Index vide. Régressif. |
| `docs/backlog/README.md` | 26 l., état réel du kit | 42 l. | Gabarit + explications de granularité. Régressif sur le contenu, mais le gabarit contient de la doctrine que l'existant n'a pas. |
| `docs/incidents/README.md` | 20 l. | 24 l. | Gabarit ; pointe vers `template.md` (local) alors que l'existant pointe vers `plugin/templates/`. |
| `docs/testing.md` | 44 l. réelles | 27 l. | Gabarit avec commentaires HTML. Régressif. |

### Non généré (délibérément)

- `docs/changelog/README.md`, `docs/changelog/_next.md` — module changelog décliné ; tous les blocs `CHANGELOG-ONLY` strippés dans les 4 fichiers concernés.
- `docs/lessons-domain.md` — pas de domaine métier riche.
- `docs/prefs/<login>.md` — jamais généré par construction.
- Aucun slash-command dans `.claude/commands/` — ils vivent dans le plugin.

### Contrôles de rendu passés

Aucun placeholder résiduel, aucun marqueur résiduel, aucune ligne vide dans un tableau, aucun espace en tête de ligne de tableau, aucune double ligne vide. **Un défaut a été trouvé** (F1) et corrigé à la main dans les 4 fichiers livrés.

---

## 2. Frictions trouvées, par ordre de gravité

### F1 — MAJEURE · bug de rendu réel, invisible au linter

**§ concerné** : Phase 5 § *Conditional blocks*.
**Ce que le texte dit** : quand la condition n'est pas remplie, « remove the markers *and* everything between them, including the trailing newline, and **absorb one blank line that framed the block** so the blanks on both sides don't collapse into a double blank line ».
**Ce qui s'est passé** : cette règle est correcte pour un bloc de **prose** encadré d'une ligne vide de chaque côté. Elle est **fausse** pour un bloc `CHANGELOG-ONLY` qui constitue la ou les **dernières lignes d'un tableau** : là il n'y a de ligne vide que *après*. En l'absorbant, le tableau se retrouve collé à l'élément suivant, sans ligne vide. **4 occurrences réelles** dans ce run :

- `CLAUDE.md` — tableau « question → doc » collé au paragraphe suivant ;
- `docs/README.md` — tableau collé au titre `## Conventions de rédaction` ;
- `docs/persistence-strategy.md` — tableau collé au titre `## Quand rien ne colle` ;
- `docs/claude-code-tooling.md` — tableau des skills collé au titre `### Plugins / serveurs MCP`.

`python3 tools/lint-templates.py` sort **OK / exit 0** : il détecte les blancs *en trop* (`check_consecutive_blank_lines`, `check_broken_tables`) mais jamais un blanc **manquant** après un tableau. Le même défaut existe dans `strip_markers` du linter (les deux implémentations partagent le bug, donc le linter valide son propre défaut).
**Ce que j'ai fait** : corrigé à la main la ligne vide dans les 4 fichiers livrés. **Correctif suggéré** : n'absorber la ligne vide suivante que si la ligne précédant le bloc retiré est vide elle aussi ; + ajouter au linter un check « une ligne `|…|` ne doit pas être suivie d'une ligne non vide qui ne commence pas par `|` ».

### F2 — MAJEURE · le mapping de Phase 5 écrase `claude.sh` sans condition

**§ concerné** : Phase 5 § *file mapping*, ligne `templates/claude.sh` → `<target>/claude.sh`, then `chmod +x` it.
**Ce que le texte dit** : rien sur le cas où la cible possède déjà un `claude.sh`. Le mapping est inconditionnel.
**Ce qui s'est passé** : le `claude.sh` de ce dépôt est une **variante volontaire** (`claude --plugin-dir ./plugin`), l'unique moyen de faire tourner le kit sur lui-même. Le gabarit l'aurait remplacé par le passe-plat `.env.claude`, cassant le dogfooding et rendant faux d'un coup `CLAUDE.md` § *Dogfooding*, `docs/testing.md` § *Comment lancer*, et l'en-tête du script lui-même.
**Asymétrie révélatrice** : le skill a prévu ce garde-fou pour `.gitignore` (« if the target already has one, **append** … rather than overwriting ») et pour `.claude/settings.json` (« do **not** overwrite it — show the relevant hook snippet(s) … or offer to merge them yourself »). Il ne l'a prévu pour **aucun** des autres fichiers du mapping.
**Ce que j'ai fait** : refusé l'écrasement (interdit du cahier), écrit sous `.bootstrap-candidate/claude.sh`.

### F3 — MAJEURE · le chemin `merge` de la Phase 0 est inapplicable tel qu'écrit

**§ concerné** : Phase 0, dernière puce + Phase 6, première puce.
**Ce que le texte dit** : « Note on `merge`: there's nothing to diff yet at this point — Phase 0 only captures *which* of the three paths to take. Run Phases 1-5 as normal to produce the candidate content, then, right before Phase 6 commits, show a diff of what would actually change per file and apply only what the user confirms. »
**Ce qui s'est passé** : la Phase 5 ne sait générer qu'**en écrivant à l'emplacement final**. Rien dans le texte ne dit **où** poser la « candidate content » quand le fichier existe déjà. Pris à la lettre : la Phase 5 écrase les 9 fichiers existants, puis la Phase 6 propose de « montrer le diff » de fichiers dont la version antérieure n'existe plus (récupérable via git ici, mais pas dans un projet non versionné — et la Phase 6 envisage explicitement `git init`, donc le cas « pas encore de git » est prévu par le skill lui-même).
**Ce que j'ai fait** : inventé la convention non écrite `<target>/.bootstrap-candidate/<même chemin relatif>` — imposée par le cahier de réponses, mais c'est exactement le trou que le skill laisse. **C'est la friction structurelle la plus grave du run** : le mode `merge` est annoncé en Phase 0, jamais outillé.

### F4 — MAJEURE · la Phase 3 n'a aucune règle de déduplication contre la cible

**§ concerné** : Phase 3, intro + § *The filter matters more than the collection* + Phase 5 § *Seeding from Phase 3*.
**Ce que le texte dit** : « Without this phase those three directories ship empty with nothing but their template entry ». Toute la phase est écrite en supposant une cible **vierge**.
**Ce qui s'est passé** : la cible a 8 ADR, 6 fichiers de backlog, 2 leçons réelles, 1 postmortem — et l'historique git récolté est *exactement* la matière première de ces artefacts. Sans garde-fou, la récolte propose de recréer ce qui est déjà écrit. Le texte ne dit jamais « lis d'abord ce que la cible contient, et ne propose que le delta ».
**Corollaire** : Phase 5 § *Seeding* dit « Delete the file's `[Template — copy this shape for a new entry]` entry once at least one real entry is in » — instruction vide de sens sur un `lessons-technical.md` qui contient déjà de vraies entrées et aucune entrée gabarit.
**Ce que j'ai fait** : appliqué une déduplication de mon cru (voir § 3). Seule la garde « propose, never write silently » m'a empêché d'écrire des doublons — ce n'est pas la même chose que de les avoir évités.

### F5 — MAJEURE · la Phase 3 est stérile sans canal interactif

**§ concerné** : Phase 3, source 2 (« ask, don't assume … in one `AskUserQuestion` ») et § *Propose, never write silently*.
**Ce que le texte dit** : rien ne peut être écrit sans confirmation item par item de l'utilisateur ; la source 2 exige une question.
**Ce qui s'est passé** : sans `AskUserQuestion` (agent délégué, orchestrateur, `claude -p`), la source 2 est inexécutable et la garde « propose, never write » rend la phase entière **incapable de produire un seul fichier**, quelle que soit la richesse des sources. La Phase 3 a donc coûté un vrai travail de lecture (60 commits) pour zéro écriture. Le texte ne prévoit aucun mode non interactif, alors que le backlog du kit contient précisément un item « invocation d'une commande par un orchestrateur ».
**Ce que j'ai fait** : exercé la source 3, produit la shortlist en § 3, **écrit zéro fichier**.

### F6 — MOYENNE · le grep TODO de la Phase 2 est ininterprétable sur un dépôt de gabarits

**§ concerné** : Phase 2, puce *Grep for `TODO`/`FIXME`/`XXX` comments across source files*.
**Ce que le texte dit** : « If there's a non-trivial number, count them and keep a few representative samples for Phase 4 ».
**Ce qui s'est passé** : 28 occurrences trouvées, dont **zéro** est un vrai TODO de code. Toutes sont soit des placeholders **délibérés** dans `plugin/templates/**` (destinés au projet généré : `# TODO : renseigner les vraies commandes…`), soit de la prose qui *parle* des TODO (`README.md`, `ADAPTING.md`, `CHANGELOG.md`, `plugin/skills/review-backlog/SKILL.md` qui les liste comme source à ne PAS utiliser). Pris à la lettre, on pose à l'utilisateur une question de triage sur 28 faux positifs. Le skill ne dit nulle part de restreindre le grep aux fichiers de code, ni d'exclure les gabarits.
**Ce que j'ai fait** : tranché seul (autorisé par le cahier) — question de triage **non posée**, aucun item de backlog créé depuis un TODO.

### F7 — MOYENNE · « never ship bare » contredit l'honnêteté exigée de l'étape de découverte

**§ concerné** : Phase 5 § *`docs/claude-code-tooling.md` — the Inventory tables specifically never ship bare* ; et le gabarit lui-même (« Cette table ne devrait pas rester vide »).
**Ce que le texte dit** : la table « Plugins / MCP servers » doit contenir « every candidate from the discovery step ».
**Ce qui s'est passé** : l'étape de découverte (subagent `claude-code-guide`) a répondu, correctement, **aucun candidat** — pas de dépendance, pas de BD, pas d'error tracking, pas de CI, ajouter un MCP serait une régression de surface d'attaque. La consigne « never ship bare » pousse alors mécaniquement à inventer un candidat de complaisance, ce que l'étape de découverte interdit par ailleurs (« each with a one-line reason tied to something actually detected (not a generic "might be useful someday") »). Les deux consignes se contredisent sur un projet sans stack.
**Ce que j'ai fait** : une ligne `_(aucun)_` avec la justification motivée, plutôt qu'une table vide ou un candidat inventé.

### F8 — MOYENNE · `{{PRIMARY_STACK}}` est substitué dans des contextes qui supposent une chaîne courte

**§ concerné** : Phase 4 § *Primary stack* + Phase 5 § *Placeholder substitution*.
**Ce qui s'est passé** : `CLAUDE.md.tpl` insère la stack dans un commentaire de bloc de code : ``# TODO : renseigner les vraies commandes pour {{PRIMARY_STACK}}``. Avec une réponse en phrase complète (celle du cahier : « Markdown … Pas d'application, pas de dépendances, pas de build. »), la ligne rendue est absurde. Rien en Phase 4 ne borne le format attendu (mot-clé court vs description).
**Ce que j'ai fait** : remplacé toute la section par les vraies commandes (ce que la Phase 5 § *Enrichment* demande de toute façon), ce qui masque le problème — mais il resterait entier sur un bootstrap sans enrichissement.

### F9 — MOYENNE · les agents `Explore` de la Phase 2 sont calibrés pour du code

**§ concerné** : Phase 2, dernière puce (« launch `Explore` agents **in parallel**, one per top-level module/directory, each asked for a structured report (module purpose, key files, conventions observed, build/test hooks) »).
**Ce qui s'est passé** : les deux « modules » de tête ici sont `plugin/` (63 fichiers, dont 38 gabarits Markdown) et `docs/` (29 fichiers de doc). Le rapport demandé est en grande partie sans objet — le sous-agent a dû conclure « aucun test automatisé dans ce module », « pas de code applicatif ». Le résultat est resté utile (il a bien caractérisé le frontmatter des `SKILL.md` et le mécanisme d'overlay), mais la grille de lecture est inadaptée à un dépôt dont le contenu *est* de la documentation.
**Ce que j'ai fait** : lancé un seul `Explore` sur `plugin/`, lu `docs/` et `tools/` moi-même.

### F10 — MINEURE · aucun repli documenté si `${CLAUDE_PLUGIN_ROOT}` / `${user_config.lang}` sont absents

**§ concerné** : Phase 1.
**Ce que le texte dit** : « `${CLAUDE_PLUGIN_ROOT}` is provided by Claude Code and points at the installed plugin's root ; there's no external checkout to locate and no env var to set. »
**Ce qui s'est passé** : affirmation fausse dans trois cas réels — exécution par un sous-agent, lancement en `--plugin-dir` (le dogfooding que le kit prescrit !), invocation `-p`. Le skill ne donne aucun repli. Idem pour `${user_config.lang}`, dont l'absence retombe sur `AskUserQuestion`, elle-même indisponible dans les mêmes cas.
**Ce que j'ai fait** : résolu `KIT_ROOT = <worktree>/plugin/templates` (adaptation d'environnement fournie par le cahier).

### F11 — MINEURE · le gabarit `claude-code-tooling.md` liste 5 skills sur 8

**§ concerné** : `plugin/templates/fr/docs/claude-code-tooling.md.tpl` (et son pendant `en`).
**Ce qui s'est passé** : la table « Skills du plugin `armature` » liste `document-standards`, `new-adr`, `capture-lessons`, `review-backlog`, `dashboard` + les deux `changelog-*` (gatés). **`/armature:bootstrap` manque** — le skill qui vient précisément de générer le fichier.
**Ce que j'ai fait** : ajouté la ligne à la main.

### F12 — MINEURE · référence datée à Forgejo

**§ concerné** : Phase 6 § *Optional remote* (« if `$FORGEJO_TOKEN` … is present ») et Phase 4 § *Suggested plugins* (« see Phase 6's Forgejo handling for why »).
**Ce qui s'est passé** : le projet est hébergé sur GitHub, le kit s'y distribue, `gh` est l'outil de la maison. Sans impact ici (aucun token), mais la mention est un vestige.

### F13 — MINEURE · questions du skill non couvertes par le cahier de réponses

Signalées comme demandé :
- **Phase 3, source 2** — « documents hors repo à verser » : question non posable, source non exercée.
- **Phase 4, *Suggested plugins/MCP servers*** — « activer maintenant vs juste consigner » : sans objet (aucun candidat), mais le cahier ne l'anticipait pas.

Toutes les autres questions du skill étaient couvertes, ou légitimement non posées (TODO : aucun vrai TODO ; conflit de style : aucun conflit déclaré-vs-observé, puisqu'il n'y a **aucun** linter/formatter configuré dans ce dépôt — section « Déclaré vs observé » supprimée comme le prescrit la Phase 5).

---

## 3. Phase 3 — verdict

### Source 1 : la conversation en cours → **rien**

Je suis un agent frais dont le premier message était l'invocation du bootstrap. **Le texte est parfaitement clair là-dessus** et m'a correctement bloqué :

> « Only mine it if the session did real work *before* the bootstrap was invoked — if the user's first message was this command, there is nothing here, and you must not invent any. »

C'est la formulation la plus nette de la phase, et elle a fait exactement son travail. Aucune invention.

### Source 2 : documents hors repo → **non exercée**

Nécessite `AskUserQuestion` (« ask, don't assume »), indisponible ; le cahier de réponses ne couvre pas cette question. La consigne « never go hunting through the filesystem outside the target directory on your own » est en revanche sans ambiguïté et a été respectée : je n'ai rien cherché hors du worktree.

### Source 3 : historique git → **exercée pour de vrai, récolte nette = zéro**

60 commits, `git log -50 --format='%h %s%n%b'` lu intégralement, plus l'ouverture ciblée du corps de 10 commits (`65277eb`, `d58bfc6`, `ef79703`, `be6c711`, `3398426`, `7e7d701`, `5a63e68`, `76faf9b`, `0b8574c`, `ef42558`). L'historique est riche : chaque commit structurant porte un corps argumenté.

**Mais tout ce qu'il contient est déjà consigné dans la cible.** Après passage du filtre du skill *puis* d'une déduplication contre l'existant (déduplication que le skill ne demande pas — voir F4) :

| Candidat | Source | Destination visée | Verdict |
|---|---|---|---|
| « Installer le plugin depuis un marketplace, même local, cache un snapshot et masque tes éditions — développer en `--plugin-dir` » | commit `be6c711` | `lessons-technical.md` | **Écarté** : déjà écrit dans `CLAUDE.md` § *Dogfooding*, `docs/testing.md`, et repris dans la leçon « Publier une version du plugin » du 2026-07-08. Seul candidat qui passait le filtre du skill ; il ne passe pas la déduplication. |
| Marqueur conditionnel : inline sur une ligne de tableau, ligne autonome admise autour d'un bloc de prose | `d58bfc6`, `65277eb` | `lessons-technical.md` | Écarté : dérivable du code (`strip_markers` + check du linter) et déjà écrit dans `CLAUDE.md` § *Working conventions*. Échoue le critère « not derivable from the code ». |
| Les 10 frictions du premier run réel des skills | `e7b9e5e`, `b65a55b` | `docs/backlog/` | Écarté : déjà `docs/backlog/first-real-run-findings.md`. |
| Diagnostic Holoon : les 6 commandes locales sont des extensions, pas des overrides | `3398426` | `docs/adr/` | Écarté : déjà ADR 0007 + `docs/backlog/command-extension-mechanism.md`. |
| Le mode `message` du hook `SessionEnd` est mort-né (stdout jamais affiché) | `ef42558` | `lessons-technical.md` | Écarté : c'est mot pour mot la leçon du 2026-07-09 déjà présente. |
| Renommage `claude-project-kit` → Armature ; passage en plugin ; profil unique | `0dfcf51`, `a76cf2f`, `4fbfb6e` | `docs/adr/` | Écarté : déjà ADR 0004 et 0005. |

**Bilan : 0 leçon, 0 item de backlog, 0 ADR écrits.**

### Le texte m'a-t-il empêché d'inventer ? — **Oui, sur les deux mécanismes prévus**

1. **La garde source 1** (« you must not invent any ») est explicite et suffisante.
2. **La garde « propose, never write silently »** a tenu : sans canal de confirmation, rien n'a été écrit — y compris le seul candidat qui passait le filtre.

**Ce contre quoi le texte ne protège pas** : proposer des **doublons** de ce qui existe déjà dans la cible (F4). Sur un bootstrap réel avec un utilisateur au bout du fil, celui-ci se serait vu proposer 6 candidats dont il aurait dû rejeter les 6 à la main — la garde aurait tenu, mais au prix d'une revue inutile. Et sur une cible vierge, un agent moins scrupuleux aurait pu écrire les 6.

**Effet de bord positif à noter** : le fait que la garde rende la phase stérile hors contexte interactif (F5) est un *symptôme*, pas un défaut de sûreté — la sûreté est bien réglée, c'est l'applicabilité qui est trop étroite.

---

## 4. Fichiers manifestement inadaptés à ce dépôt

1. **`docs/adr/template.md`, `docs/plans/template.md`, `docs/incidents/template.md`** — ce dépôt refuse **délibérément** de les dupliquer. `docs/adr/README.md` dit noir sur blanc : « le kit utilise exactement le gabarit qu'il génère dans les projets — voir `../../plugin/templates/fr/docs/adr/template.md` ». Les générer crée une seconde copie qui divergera silencieusement de la source. Le skill n'a aucun moyen de savoir que la cible *est* le kit — c'est le seul cas où l'auto-application est structurellement fausse.
2. **`claude.sh`** — variante volontaire (F2). Le candidat est un script sans rapport.
3. **`.env.claude.example`** — décrit un mécanisme (« Chargé automatiquement par `./claude.sh` ») que le `claude.sh` de ce dépôt **ne fait pas**. Fichier orphelin ; l'entrée `.env.claude` ajoutée au `.gitignore` protège un fichier qui ne sera jamais lu.
4. **Les 6 candidats `docs/` en collision** (`lessons-technical.md`, `adr/README.md`, `plans/README.md`, `backlog/README.md`, `incidents/README.md`, `testing.md`) — versions vierges de fichiers riches et à jour. Aucun n'apporte quoi que ce soit, sauf `backlog/README.md` dont le gabarit contient de la doctrine de granularité que l'existant n'a pas (à récupérer par extrait, pas par remplacement).
5. **`tools/session-end-capture.sh` + hook `SessionEnd`** — défendable, mais ce dépôt est précisément l'endroit où ce script est *développé* : l'activer ici fait tourner la version du working tree sur le working tree, et une session de travail sur le hook déclencherait le hook en cours de modification. À arbitrer consciemment.
6. **`docs/architecture.md` § « Modèle de données »** — section sans objet (aucune BD, aucune entité). Je l'ai détournée pour décrire le graphe d'artefacts backlog → ADR → plan plutôt que de la laisser vide ; c'est un choix, pas ce que le gabarit demande.
7. **`tools/generate-dashboard.py`** — utile en principe (le skill `/armature:dashboard` existe et le dépôt a 8 ADR + 8 plans), mais le dépôt n'a jamais eu de `docs/dashboard.html`. À adopter volontairement, pas par effet de bord du bootstrap.

---

## 5. Ce que le skill aurait cassé sans les garde-fous

Suivi à la lettre, sans les interdits du cahier, le run aurait **écrasé 9 fichiers** puis les aurait **commités** sous `docs: bootstrap Claude environment` (Phase 6) :

| Fichier | Ce qui aurait été perdu |
|---|---|
| `claude.sh` | Le lanceur de dogfooding — **le seul moyen de faire tourner le kit sur lui-même**. Casse en même temps `CLAUDE.md` § *Dogfooding* et `docs/testing.md` § *Comment lancer*, qui deviennent faux. |
| `CLAUDE.md` | « What this repo is », « Structure », le long paragraphe « Where things stand » (état de 8 ADR, historique des décisions), et les 4 conventions de travail (parité en/fr, marqueurs, CHANGELOG à la main, dogfooding). Non reconstituable autrement qu'en relisant tout le dépôt. |
| `docs/lessons-technical.md` | 2 leçons réelles (hooks `SessionEnd`, mécanique de publication du plugin) — précisément le type de contenu que le kit existe pour protéger. |
| `docs/adr/README.md` | L'index des 8 ADR + le paragraphe « pourquoi le kit a son propre `docs/adr/` » + le pointeur de format vers `plugin/templates/`. |
| `docs/plans/README.md` | L'index des plans. |
| `docs/backlog/README.md` | L'état réel du backlog du kit (2 sujets ouverts, 5 clos avec leur raison, 2 en fond de tiroir). |
| `docs/testing.md` | 44 lignes de doctrine de test réelle → 27 lignes de gabarit à trous. |
| `docs/incidents/README.md` | L'index ; l'incident du 2026-07-01 serait resté sur disque mais délié. |
| `.claude/settings.json` | **Aurait survécu** — c'est le seul fichier pour lequel la Phase 5 a explicitement prévu le garde-fou (« do not overwrite it »). |

**Le compte est net** : la Phase 5 protège explicitement **2 fichiers sur 24** (`.gitignore` par append, `.claude/settings.json` par refus d'écrasement) et écrase tous les autres sans poser de question. Le seul rempart annoncé est le chemin `merge` de la Phase 0 — qui, comme le montre F3, n'est outillé nulle part.

Effet secondaire non destructif mais indésirable : l'ajout de `.env.claude` au `.gitignore` pour un mécanisme inutilisé ici, et la création de trois `template.md` que le dépôt évite délibérément.

---

## 6. Phase 6 — non exécutée (entorse assumée)

Aucun `git add`, aucun commit, aucun tag, aucun push. Ce que la Phase 6 aurait fait :

1. **Chemin `merge`** : montrer, fichier par fichier, le diff des 9 collisions et n'appliquer que les hunks confirmés. *(Inapplicable tel qu'écrit — F3.)*
2. `git init` : sans objet, le dépôt est déjà versionné.
3. Stager les 14 nouveaux fichiers + le `.gitignore` modifié + ce qui aurait été retenu du merge, et commiter `docs: bootstrap Claude environment` (commit `docs:` distinct, le dépôt ayant déjà un historique). Aucun `git add -f` nécessaire (vérification `.gitignore` de la Phase 5 : aucun motif large n'avale `.env.claude.example` ni `claude.sh`).
4. **Remote optionnel** : `$FORGEJO_TOKEN` absent de l'environnement → sous-étape sautée et signalée dans le résumé, comme le prescrit le texte.

État laissé : **working tree modifié, rien de stagé**, pour arbitrage manuel.

---

## 7. Phase 7 — résumé du run

- **Auto-détecté (Phase 2)** : stack Markdown + Python 3 stdlib + Bash ; aucun manifeste, aucune dépendance, aucune CI ; indentation Python 4 espaces / guillemets simples ; Bash `set -euo pipefail` ; **aucun linter/formatter configuré** → aucun conflit « déclaré vs observé », section supprimée. Le seul contrôle automatisé est `tools/lint-templates.py`.
- **Reste en `TODO`** : `docs/claude-code-tooling.md` §§ *Stratégie*, *Hors périmètre*, *Comment évaluer*, *Socle de sécurité*, *Références* (intentionnellement laissés à l'équipe par le skill) ; `docs/architecture.md` § *Préoccupations transverses* est rempli mais mérite relecture ; `docs/testing.md` candidat est à jeter au profit de l'existant.
- **Phase 3** : rien écrit (§ 3).
- **Plugins/MCP** : aucun candidat, aucune activation, aucune commande de setup en attente.
- **`./claude.sh`** : à **ne pas** remplacer ici — voir F2. Le mécanisme `.env.claude` (gitignored, jamais commité) n'est pas en vigueur dans ce dépôt malgré le `.env.claude.example` généré.
- **Auto-capture de fin de session** : configurée dans le candidat `.claude/settings.json` uniquement (le fichier réel n'a pas été touché) ; le script est en place et exécutable. Il écrit mais ne commite jamais — des fichiers non commités peuvent attendre au début de la session suivante (`tools/session-end-capture.log`). Le rappel « travail non commité » de `claude.sh`, lui, n'existe pas dans la variante dogfooding de ce dépôt.
