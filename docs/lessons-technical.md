# Leçons techniques — Armature

Pièges non-évidents rencontrés en développant/distribuant le kit, qu'on ne peut pas reconstituer en lisant le code. Ajout **en tête** (append-only) ; une leçon invalidée est *superseded* (pas réécrite), son corps conservé en blockquote. Voir aussi `docs/testing.md` (dogfooding) et `CHANGELOG.md` (releases).

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
