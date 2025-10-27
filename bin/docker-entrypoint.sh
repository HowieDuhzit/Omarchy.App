#!/usr/bin/env bash
set -euo pipefail

: "${RAILS_ENV:=production}"

echo "[entrypoint] DATABASE_URL: ${DATABASE_URL:-NOT_SET}"
echo "[entrypoint] SERVICE_URL_POSTGRES: ${SERVICE_URL_POSTGRES:-NOT_SET}"
echo "[entrypoint] SERVICE_PASSWORD_POSTGRES: ${SERVICE_PASSWORD_POSTGRES:-NOT_SET}"

# Construct proper PostgreSQL connection string for internal use
if [ -n "${SERVICE_PASSWORD_POSTGRES:-}" ]; then
  echo "[entrypoint] Using internal PostgreSQL connection"
  export DATABASE_URL="postgresql://postgres:${SERVICE_PASSWORD_POSTGRES}@postgres:5432/omarchy_directory_production"
elif [ -n "${DATABASE_URL:-}" ] && [[ "${DATABASE_URL}" =~ ^postgresql:// ]]; then
  echo "[entrypoint] Using provided PostgreSQL DATABASE_URL"
  export DATABASE_URL
else
  echo "[entrypoint] No valid database configuration found, skipping database operations"
  echo "[entrypoint] Starting: $*"
  exec "$@"
fi

echo "[entrypoint] Final DATABASE_URL: ${DATABASE_URL}"

echo "[entrypoint] Checking gems..."
bundle check

echo "[entrypoint] Waiting for PostgreSQL to be ready..."
until pg_isready -h postgres -p 5432 -U postgres >/dev/null 2>&1; do
  echo "[entrypoint] Waiting for PostgreSQL..."
  sleep 2
done
echo "[entrypoint] PostgreSQL is ready!"

echo "[entrypoint] Preparing database..."
# Ensure binstubs are executable when bind-mounted from host
chmod +x bin/rails bin/rake || true
bin/rails db:prepare

echo "[entrypoint] Seeding database..."
bin/rails db:seed

echo "[entrypoint] Starting: $*"
exec "$@"
