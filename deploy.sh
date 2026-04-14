#!/bin/bash
set -euo pipefail

# Deploy HoMonRadeau to production VPS
# Usage: ./deploy.sh

ENV_FILE=".env.prod"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Copy .env.prod.example and fill in values."
  exit 1
fi

echo "==> Building production image..."
docker compose -f docker-compose.prod.yml --env-file "$ENV_FILE" build

echo "==> Running database migrations..."
docker compose -f docker-compose.prod.yml --env-file "$ENV_FILE" run --rm app /app/bin/migrate

echo "==> Starting services..."
docker compose -f docker-compose.prod.yml --env-file "$ENV_FILE" up -d

echo "==> Done! App should be available at https://${PHX_HOST:-hmr.bellec.in}"
