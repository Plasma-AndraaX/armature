# Leçons techniques — Armature

Pièges non-évidents rencontrés en développant/distribuant le kit, qu'on ne peut pas reconstituer en lisant le code. Ajout **en tête** (append-only) ; une leçon invalidée est *superseded* (pas réécrite), son corps conservé en blockquote. Voir aussi `docs/testing.md` (dogfooding) et `CHANGELOG.md` (releases).

## Un `/reload-plugins` ne vaut que pour les éditions qui le précèdent — et rien ne signale l'écart

`--plugin-dir ./plugin` rend le dogfooding *live*, mais pas *continu* : `/reload-plugins` charge un **instantané**. Toute édition d'un `SKILL.md` postérieure au reload reste invisible jusqu'au reload suivant, et le texte du skill injecté dans la conversation peut donc **contredire le fichier sur disque** sans qu'aucun message ne le dise. Le piège n'est pas le cache d'une install (voir les deux leçons ci-dessous) : ici il n'y a qu'une seule source, elle est simplement figée dans le temps.

- **Recharger après chaque édition**, pas une fois en début de session. Un reload fait *avant* d'éditer ne sert à rien.
- **Quand une modification « ne prend pas », vérifier l'instantané avant de soupçonner son propre texte** : comparer le bloc injecté au fichier (`git log -1 -- <fichier>` + un `grep` sur la phrase qu'on vient d'écrire). On cherche sinon un défaut de rédaction dans un texte qui n'est pas celui qui tourne.

Cas réel, le 2026-09-12 : deux lots d'éditions successifs sur `plugin/skills/review-backlog/SKILL.md` avec un seul `/reload-plugins` entre les deux. Le second run de la commande a été injecté avec l'ancienne structure (la nouvelle section en position 6) alors que le disque et `HEAD` portaient la nouvelle (position 1) — écart détecté seulement parce que la sortie attendue ne collait pas. Noter que `docs/testing.md` dit « éditer puis `/reload-plugins` recharge à chaud » : c'est vrai, et c'est exactement ce qui rassure à tort sur l'ordre inverse.

_Captured 2026-09-12._

## Une commande qui agrège des sources *écrites* est aveugle à la session en cours, même quand son texte la mentionne

Deux fois à trois jours d'écart, une commande du kit a ignoré la conversation qui la lançait alors que son propre texte l'évoquait. `/armature:bootstrap` ne lisait que le *code* et générait `lessons-technical.md`, `docs/backlog/` et `docs/adr/` vides pendant que la session tenait 17 artefacts réels (corrigé par l'[ADR 0008](adr/0008-recolte-contexte-bootstrap.md)). Puis `/armature:review-backlog`, dont les deux sources canoniques sont le README du backlog et les plans `in-progress` : sa section « Hot now » disait bien « items the **current session** makes relevant », mais comme *critère de reclassement d'items déjà fichés* — jamais comme source. Tout ce qui n'était pas consigné mourait donc avec la session.

La règle, en rédigeant un skill : **« la conversation en cours » doit être une étape numérotée du processus, pas une mention dans une description de section.** Une mention descriptive ne produit rien — d'autant qu'une consigne d'agrégation du type « don't invent anything, aggregate from canonical sources » pousse activement dans l'autre sens et doit alors être explicitement bornée aux sources écrites. Toute étape de ce genre porte ses deux gardes : **proposer sans jamais écrire** (la commande reste en lecture seule, la consignation est la décision de l'utilisateur) et **ne rapporter que ce qui a été dit** (une section vide annoncée telle quelle, pas remplie de travail plausible).

Deux occurrences indépendantes font un motif, pas un accident : les 6 autres skills n'ont pas été audités sur ce point.

_Captured 2026-09-12._

## Une install de plugin faite « juste pour un run » survit au run — et retombe sur le dépôt de dev

Le 2026-09-09, pour faire tourner `/armature:bootstrap` dans un worktree isolé, Armature a été installé en scope **`user`** (et, 17 min plus tard, en scope `local` sur un répertoire d'overlay). Le worktree a disparu le jour même ; les installs, non. Pendant 24 h, le dépôt du kit a donc eu **deux** sources concurrentes pour les `/armature:*` : le snapshot en cache de l'install `user`, actif partout, et le `--plugin-dir ./plugin` de `./claude.sh`.

La leçon du 2026-07-08 dit « ne pas installer le plugin *dans* ce repo ». Elle ne couvre pas ce cas-ci : l'install est faite **ailleurs**, pour autre chose, et retombe ici sans que personne ne l'ait décidé.

- **Le scope `user` est global.** Il n'existe pas de répertoire où il ne s'applique pas — y compris le dépôt du kit, où toute la doctrine de dogfooding repose sur `--plugin-dir`.
- **`claude plugin list` ne montre pas le plugin chargé par `--plugin-dir`** : il n'est pas dans le registre des installs. Ne rien voir d'anormal à l'écran ne prouve donc pas l'absence de coexistence.
- **Il existe un `claude plugin disable <plugin> --scope project`**, qui écrit `"enabledPlugins": {"<plugin>@<marketplace>": false}` dans le `.claude/settings.json` du projet (donc versionnable). **Non tranché** : on n'a pas pu établir s'il épargne le plugin chargé par `--plugin-dir`. Un test en `-p` n'expose aucun skill de plugin *même sans* le réglage, donc il ne discrimine rien ; le test décisif est interactif.
- **Parade retenue** : pas d'install permanente pour un besoin ponctuel. Désinstaller après le run (`claude plugin uninstall <plugin>@<marketplace> --scope user`) et réinstaller à la demande, plutôt que de masquer la coexistence par un réglage dont l'effet n'est pas démontré.

_Captured 2026-09-10._

## Un hook `SessionEnd` ne peut pas parler à l'utilisateur — et se fait annuler s'il est lent

Deux propriétés non-évidentes des hooks `SessionEnd` de Claude Code, apprises en debuggant un « Hook cancelled » à la sortie (sur un projet bootstrappé, en WSL2 `/mnt/c`) :

- **Son stdout n'est jamais affiché.** Les hooks tournent « without controlling terminal » et `SessionEnd` est non-bloquant : sa sortie et son code retour sont ignorés. Donc tout design qui compte sur un hook `SessionEnd` pour *afficher un bandeau* à l'utilisateur est mort-né — c'était exactement le cas du mode `message` de notre hook de capture : le bandeau ne s'imprimait jamais. Un message visible doit venir d'un process qui possède le TTY : le wrapper `claude.sh` (après la session), ou le `SessionStart` suivant (qui, lui, injecte du contexte).
- **Ce n'est pas un timeout, c'est une annulation à l'extinction.** Le budget par défaut d'un hook `command` est 600 s et `SessionEnd` n'a pas de budget réduit — donc « Hook cancelled » ≠ « Hook timed out ». Au moment où le CLI s'éteint, il **n'attend pas** que le hook finisse : un hook qui fait du travail lent SYNCHRONE (`git status`, `grep` sur le transcript, `sleep`) est coupé en plein milieu, surtout sur FS lent. Parade : lire le payload puis détacher immédiatement tout le travail lent (`setsid` sur une copie du script) et faire `exit 0` en < 1 s ; le travail détaché, réparenté à init, finit tranquillement (il n'a le droit d'écrire que des fichiers, pas l'écran — cf. point précédent).

Corollaire de design, appliqué au kit : **le rappel** (juste un `git status` + affichage) appartient à `claude.sh` ; **la capture** (a besoin du `transcript_path`, que seul le payload `SessionEnd` fournit) reste un hook `SessionEnd`, mais détaché. Le mode `message` du hook a donc été supprimé, et l'`auto` durci.

_Captured 2026-07-09._

## Publier une version du plugin et la faire *prendre* chez un consommateur : la mécanique piégeuse

Au moment de couper une release Armature puis de la faire tourner sur un projet consommateur (p. ex. Holoon), quatre pièges non-devinables coûtent facilement une heure ou deux — et ils reviennent à **chaque** release :

- **C'est `plugin/.claude-plugin/plugin.json` `version` qui pilote la détection d'install/update**, pas le fichier `VERSION` (lui n'est que cosmétique / lisible-humain). Bumper `VERSION` + `CHANGELOG` sans bumper `plugin.json` → `/plugin update` ne voit aucune nouvelle version.
- **Le clone de marketplace local ne se rafraîchit pas tout seul.** `/plugin update` réinstalle depuis `~/.claude/plugins/marketplaces/<nom>` (un simple `git clone`). S'il est en retard sur `origin/master`, tu réinstalles la version *périmée*, sans erreur. → toujours `/plugin marketplace update <nom>` (ou `git pull` le clone) **avant** `/plugin update`.
- **`/plugin update` (slash) vise le scope `user` par défaut.** Un plugin installé en **scope projet** (dans le `.claude/settings.json` du projet) fait échouer la commande avec « not installed at scope user ». → passer par la **CLI** : `claude plugin update <plugin>@<marketplace> --scope project`. Le cache (`~/.claude/plugins/cache/<…>/<version>/`) est **partagé** entre scopes — un seul re-cache sert tous les scopes.
- **Développer le plugin en live = `claude --plugin-dir ./plugin` uniquement.** Toute install par marketplace (distante *ou* locale) copie un snapshot en cache ; les éditions du working tree n'y apparaissent pas. C'est le dogfooding décrit dans `docs/testing.md` / `claude.sh`.

Exemple concret (2026-07-08) : la mise à jour du plugin sur Holoon a échoué deux fois avant qu'on trouve que (a) le clone de marketplace était **16 commits derrière** `origin/master`, et (b) `/plugin update` visait le scope `user` alors qu'Armature y est installé en scope projet.

_Captured 2026-07-08._
