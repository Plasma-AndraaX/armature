#!/usr/bin/env bash
# Charge les secrets/variables d'environnement locaux, puis lance Claude Code.
#
# Les vraies valeurs vont dans .env.claude (gitignored — ne jamais le commiter).
# Partir de .env.claude.example, qui documente à la fois les valeurs en clair
# et comment résoudre une valeur depuis la CLI d'un gestionnaire de mots de
# passe plutôt que de la stocker en clair.
#
# Usage : ./claude.sh [arguments CLI claude quelconques]
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/.env.claude"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
else
  echo "Aucun .env.claude trouvé — copie .env.claude.example et renseigne tes valeurs si ce projet en a besoin. Lancement de claude sans variables d'env supplémentaires." >&2
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude introuvable dans le PATH — installe Claude Code (https://claude.com/claude-code) avant de relancer ce script." >&2
  exit 1
fi

# On ne fait PAS d'exec : le wrapper doit reprendre la main quand la session se
# termine, pour afficher le rappel ci-dessous. Un hook SessionEnd ne le peut pas
# (il tourne sans terminal de contrôle — son stdout n'est jamais montré) ; ce
# wrapper, lui, possède le TTY.
set +e
claude "$@"
rc=$?
set -e

# Rappel de fin de session : s'il reste du travail non commité, penser à capturer
# avant de commiter. Ça vit ici (et pas dans un hook) parce que le wrapper possède
# l'écran.
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   && [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
  cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Travail non commité dans ce projet.
Avant de commiter, pense à capturer ce qui le mérite :
  /armature:capture-lessons  (et /armature:changelog-capture si le projet l'utilise)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi

exit "$rc"
