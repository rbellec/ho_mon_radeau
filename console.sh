#!/bin/bash
set -euo pipefail

# Open an IEx console connected to the running application.
# Usage:
#   ./console.sh        → development (default)
#   ./console.sh prod   → production

ENV="${1:-dev}"

case "$ENV" in
  prod)
    ENV_FILE=".env.prod"
    if [ ! -f "$ENV_FILE" ]; then
      echo "Error: $ENV_FILE not found."
      exit 1
    fi
    echo "==> Connecting to production console..."
    docker compose -f docker-compose.prod.yml --env-file "$ENV_FILE" \
      exec app /app/bin/ho_mon_radeau remote
    ;;
  dev)
    echo "==> Connecting to development console..."
    docker compose exec app iex -S mix
    ;;
  *)
    echo "Usage: ./console.sh [dev|prod]"
    exit 1
    ;;
esac
