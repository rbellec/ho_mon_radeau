#!/bin/bash
set -euo pipefail

# Deploy HoMonRadeau to production VPS
# Usage: ./deploy.sh
#
# Full workflow: git pull && ./deploy.sh

ENV_FILE=".env.prod"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Copy .env.prod.example and fill in values."
  exit 1
fi

# Source env file to read PHX_HOST for the final message
set -a; source "$ENV_FILE"; set +a

COMPOSE="docker compose -f docker-compose.prod.yml --env-file $ENV_FILE"

echo "==> Pulling latest code..."
git pull --ff-only

echo "==> Building production image..."
$COMPOSE build

echo "==> Running database migrations..."
$COMPOSE run --rm app /app/bin/migrate

echo "==> Restarting services..."
$COMPOSE up -d

echo "==> Done! App available at https://${PHX_HOST}"
