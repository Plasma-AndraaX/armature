#!/bin/bash
# Worker du hook SessionEnd — capture headless (mode auto).
# Câblé depuis .claude/settings.json comme : bash tools/session-end-capture.sh
# Pas fait pour être lancé à la main (mais sans danger si tu le fais — il vérifiera
# juste le gate et ne trouvera probablement rien à faire hors d'un vrai appel
# SessionEnd de Claude Code).
#
# Ce worker ne fait plus qu'UNE chose : lancer, détaché, un `claude -p` qui capture
# leçons/changelog depuis le transcript de la session. Le rappel « travail non
# commité » NE passe plus par ici — un hook SessionEnd tourne sans terminal de
# contrôle, donc son stdout n'est jamais affiché à l'utilisateur ; ce rappel vit
# désormais dans `claude.sh`, qui possède le TTY.
#
# Point clé de robustesse : un hook SessionEnd qui fait du travail lent (git, grep,
# I/O transcript, `sleep`) de façon SYNCHRONE se fait annuler quand le CLI s'éteint
# (« Hook cancelled »), avant d'avoir rien fait. Donc on lit le payload, on relance
# une copie DÉTACHÉE de ce script (setsid), et on rend la main tout de suite — tout
# le travail lent se passe dans la copie détachée, réparentée à init.
#
# Pattern crédité : adapté d'un hook validé sur un workspace personnel (garde
# anti-récursion, attente du transcript, cap en octets, prompt en fichier temp pour
# éviter les soucis d'échappement, `claude -p` headless). Durci pour un kit public
# générique : les --allowedTools du run headless excluent Bash (Read/Edit/Write/
# Glob/Grep suffisent pour écrire dans les fichiers de leçons/changelog), et il ne
# touche jamais à git — aucun commit, jamais.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/session-end-capture.log"

# --- Garde anti-récursion : le run headless ci-dessous positionne ceci avant de
# démarrer sa propre session ; si son propre hook SessionEnd se déclenche, ça
# l'arrête net. ---
if [ -n "$CLAUDE_HOOK_SPAWNED" ]; then
    exit 0
fi

# --- Détachement immédiat : on rend la main au CLI en < 1 s pour ne jamais se
# faire annuler. On lit le payload (il vient d'un pipe, il faut le consommer
# maintenant) puis on relance une copie détachée de ce script qui, elle, fait tout
# le travail lent. ---
if [ -z "$CLAUDE_CAPTURE_DETACHED" ]; then
    PAYLOAD=$(cat)
    printf '%s' "$PAYLOAD" | CLAUDE_CAPTURE_DETACHED=1 setsid bash "$0" >/dev/null 2>&1 &
    exit 0
fi

# ===================== à partir d'ici : worker détaché =====================
PAYLOAD=$(cat)
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // ""' 2>/dev/null)
SESSION_CWD=$(echo "$PAYLOAD" | jq -r '.cwd // ""' 2>/dev/null)
SESSION_CWD="${SESSION_CWD:-$SCRIPT_DIR/..}"

echo "--- session-end-capture (auto) à $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"

if [ -z "$TRANSCRIPT" ]; then
    echo "Pas de transcript_path dans le payload, sortie." >> "$LOG_FILE"
    exit 0
fi

# --- Gate : ne continuer que si quelque chose vaut plausiblement d'être capturé. ---
# Heuristique, pas une garantie — même posture "best-effort" que le reste du kit.
DIRTY=false
if git -C "$SESSION_CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    [ -n "$(git -C "$SESSION_CWD" status --porcelain 2>/dev/null)" ] && DIRTY=true
fi
WROTE_SOMETHING=false
if [ -f "$TRANSCRIPT" ] && grep -qE '"name"\s*:\s*"(Write|Edit)"' "$TRANSCRIPT" 2>/dev/null; then
    WROTE_SOMETHING=true
fi
ALREADY_CAPTURED=false
if [ -f "$TRANSCRIPT" ] && grep -qE 'capture-lessons|changelog-capture' "$TRANSCRIPT" 2>/dev/null; then
    ALREADY_CAPTURED=true
fi

if { [ "$DIRTY" = false ] && [ "$WROTE_SOMETHING" = false ]; } || [ "$ALREADY_CAPTURED" = true ]; then
    echo "Gate non atteint (dirty=$DIRTY wrote=$WROTE_SOMETHING already_captured=$ALREADY_CAPTURED) — rien à faire." >> "$LOG_FILE"
    exit 0
fi

echo "Gate atteint (dirty=$DIRTY wrote=$WROTE_SOMETHING) — lancement de la capture headless." >> "$LOG_FILE"

# Attend un peu au cas où le transcript ne serait pas encore sur disque.
if [ ! -f "$TRANSCRIPT" ]; then
    for _ in 1 2 3; do
        sleep 1
        [ -f "$TRANSCRIPT" ] && break
    done
fi
if [ ! -f "$TRANSCRIPT" ]; then
    echo "Le transcript n'est jamais apparu sur disque, sortie." >> "$LOG_FILE"
    exit 0
fi

MAX_BYTES=4194304  # cap aux 4 derniers Mo — contrôle de coût/contexte, pas une contrainte dure

# Le prompt va dans son propre fichier temporaire pour éviter d'inliner du texte
# de prompt arbitraire dans une commande shell — sidesteppe les soucis d'échappement.
PROMPT_FILE=$(mktemp /tmp/claude-session-capture-prompt-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
Tu tournes de façon non-interactive, juste après la fin d'une session Claude Code
dans ce projet. On t'a envoyé sur stdin la fin du transcript de cette session — le
format JSONL interne de Claude Code (un objet JSON par ligne, peut varier d'une
version à l'autre ; parse-le de façon défensive pour extraire les messages
utilisateur/assistant et l'usage d'outils, ne suppose pas un schéma fixe).

Ta tâche : applique EXACTEMENT les mêmes filtres de pertinence que le skill
`/armature:capture-lessons` du plugin `armature` et, si ce projet utilise un changelog,
`/armature:changelog-capture` — suis leurs critères précisément, n'improvise pas
d'autres critères. Écris ensuite toute entrée qualifiante directement dans les
fichiers qu'ils précisent (typiquement `docs/lessons-technical.md`,
`docs/lessons-domain.md` s'il existe, `docs/changelog/_next.md` s'il existe).

Règles strictes :
- Ne lance aucune commande git. Ne commite pas. L'utilisateur relit et commite à
  sa prochaine session — cette étape de relecture n'est pas optionnelle, juste
  déplacée plus tard.
- La plupart des sessions ne produisent rien qui vaille d'être capturé. Si c'est
  le cas ici, ne fais rien et dis-le — ne fabrique pas une leçon pour justifier
  d'avoir tourné.
- Affiche une courte synthèse à la fin de ce que tu as capturé (ou "rien à
  capturer cette fois") — c'est loggé pour que l'utilisateur le lise plus tard.
PROMPT_EOF

# On est déjà détaché (setsid en tête) : pas besoin d'un runner imbriqué, on lance
# le claude -p directement. La garde anti-récursion empêche son propre SessionEnd
# de relancer une capture.
export CLAUDE_HOOK_SPAWNED=1
cd "$SESSION_CWD" || exit 0
tail -c "$MAX_BYTES" "$TRANSCRIPT" | claude -p "$(cat "$PROMPT_FILE")" \
    --allowedTools "Read Edit Write Glob Grep" \
    --permission-mode acceptEdits \
    >> "$LOG_FILE" 2>&1
echo "claude -p terminé avec le code : $?" >> "$LOG_FILE"
echo "--- fin session-end-capture (auto) ---" >> "$LOG_FILE"
rm -f "$PROMPT_FILE"

exit 0
