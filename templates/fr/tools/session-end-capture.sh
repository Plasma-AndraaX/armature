#!/bin/bash
# Worker du hook SessionEnd — rappel conditionnel ou auto-capture headless.
# Câblé depuis .claude/settings.json comme : bash tools/session-end-capture.sh <message|auto>
# Pas fait pour être lancé à la main (mais sans danger si tu le fais — il vérifiera
# juste le gate et ne trouvera probablement rien à faire hors d'un vrai appel
# SessionEnd de Claude Code).
#
# Pattern crédité : adapté d'un hook validé sur un workspace personnel (garde
# anti-récursion, attente du transcript, cap en octets, script mktemp avec
# substitution différée du fichier de prompt pour éviter les soucis
# d'échappement, `claude -p` headless détaché). Durci pour un kit public
# générique : les --allowedTools du run headless excluent Bash (Read/Edit/
# Write/Glob/Grep suffisent pour écrire dans les fichiers de leçons/changelog),
# et il ne touche jamais à git — aucun commit, jamais.

MODE="${1:-message}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/session-end-capture.log"

# --- Garde anti-récursion : le run headless ci-dessous positionne ceci avant
# de démarrer sa propre session ; si son propre hook SessionEnd se déclenche,
# ça l'arrête net. ---
if [ -n "$CLAUDE_HOOK_SPAWNED" ]; then
    exit 0
fi

PAYLOAD=$(cat)
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // ""' 2>/dev/null)
SESSION_CWD=$(echo "$PAYLOAD" | jq -r '.cwd // ""' 2>/dev/null)
SESSION_CWD="${SESSION_CWD:-$SCRIPT_DIR/..}"

echo "--- session-end-capture ($MODE) à $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"

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

echo "Gate atteint (dirty=$DIRTY wrote=$WROTE_SOMETHING) — mode=$MODE" >> "$LOG_FILE"

# --- Mode message : affiche juste un rappel visible, aucune automatisation. ---
if [ "$MODE" = "message" ]; then
    cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cette session a du travail non commité qui n'a pas l'air capturé.
Lance `./claude.sh --continue` pour la reprendre, puis `/capture-lessons`
et (si ce projet l'utilise) `/changelog-capture`.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 0
fi

# --- Mode auto : lance un Claude headless détaché qui fait la capture lui-même. ---
if [ "$MODE" != "auto" ]; then
    echo "Mode '$MODE' inconnu, traité comme message-only (aucun rappel affiché sur ce chemin de sortie)." >> "$LOG_FILE"
    exit 0
fi

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

# Le prompt va dans son propre fichier temporaire pour que le script runner
# ci-dessous puisse différer sa lecture à l'exécution (`\$(cat "$PROMPT_FILE")`)
# plutôt que d'essayer d'inliner du texte de prompt arbitraire dans une
# commande shell — évite complètement les problèmes d'échappement.
PROMPT_FILE=$(mktemp /tmp/claude-session-capture-prompt-XXXXXX.md)
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
Tu tournes de façon non-interactive, juste après la fin d'une session Claude Code
dans ce projet. On t'a envoyé sur stdin la fin du transcript de cette session — le
format JSONL interne de Claude Code (un objet JSON par ligne, peut varier d'une
version à l'autre ; parse-le de façon défensive pour extraire les messages
utilisateur/assistant et l'usage d'outils, ne suppose pas un schéma fixe).

Ta tâche : applique EXACTEMENT les mêmes filtres de pertinence que
`.claude/commands/capture-lessons.md` de ce projet et, s'il existe,
`.claude/commands/changelog-capture.md` — lis ces deux fichiers d'abord et suis
leurs critères précisément, n'improvise pas d'autres critères. Écris ensuite toute
entrée qualifiante directement dans les fichiers qu'ils précisent (typiquement
`docs/lessons-technical.md`, `docs/lessons-domain.md` s'il existe,
`docs/changelog/_next.md` s'il existe).

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

RUNNER=$(mktemp /tmp/claude-session-capture-runner-XXXXXX.sh)
cat > "$RUNNER" <<RUNNER_EOF
#!/bin/bash
export CLAUDE_HOOK_SPAWNED=1
cd "$SESSION_CWD" || exit 0
tail -c $MAX_BYTES "$TRANSCRIPT" | claude -p "\$(cat "$PROMPT_FILE")" \\
    --allowedTools "Read Edit Write Glob Grep" \\
    --permission-mode acceptEdits \\
    >> "$LOG_FILE" 2>&1
echo "claude -p terminé avec le code : \$?" >> "$LOG_FILE"
echo "--- fin session-end-capture (auto) ---" >> "$LOG_FILE"
rm -f "$PROMPT_FILE" "$RUNNER"
RUNNER_EOF
chmod +x "$RUNNER"

setsid bash "$RUNNER" </dev/null &>/dev/null &
echo "Capture headless lancée en arrière-plan (pid : $!)" >> "$LOG_FILE"

exit 0
