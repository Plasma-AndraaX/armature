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

exec claude "$@"
