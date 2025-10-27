#!/usr/bin/env bash
set -euo pipefail

: "${RAILS_ENV:=production}"

echo "[entrypoint] DATABASE_URL: ${DATABASE_URL:-NOT_SET}"
echo "[entrypoint] SERVICE_URL_POSTGRES: ${SERVICE_URL_POSTGRES:-NOT_SET}"

# Use DATABASE_URL if provided (Coolify magic variable)
if [ -n "${DATABASE_URL:-}" ]; then
  echo "[entrypoint] Using provided DATABASE_URL"
  export DATABASE_URL
elif [ -n "${SERVICE_URL_POSTGRES:-}" ]; then
  echo "[entrypoint] Using SERVICE_URL_POSTGRES as DATABASE_URL"
  export DATABASE_URL="${SERVICE_URL_POSTGRES}"
else
  echo "[entrypoint] No database URL provided, skipping database operations"
  echo "[entrypoint] Starting: $*"
  exec "$@"
fi

echo "[entrypoint] Checking gems..."
bundle check

echo "[entrypoint] Preparing database..."
# Ensure binstubs are executable when bind-mounted from host
chmod +x bin/rails bin/rake || true
bin/rails db:prepare

echo "[entrypoint] Seeding database..."
bin/rails db:seed

echo "[entrypoint] Starting: $*"
exec "$@"
