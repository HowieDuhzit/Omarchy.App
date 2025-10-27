#!/usr/bin/env bash
set -euo pipefail

: "${RAILS_ENV:=production}"
: "${PGHOST:=postgres}"
: "${PGPORT:=5432}"
: "${PGUSER:=postgres}"
: "${PGPASSWORD:=${SERVICE_PASSWORD_POSTGRES}}"
: "${PGDATABASE:=omarchy_directory_production}"

# Set database URL for Rails
export DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
export RAILS_ENV PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE

echo "[entrypoint] Waiting for Postgres at ${PGHOST}:${PGPORT}..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" >/dev/null 2>&1; do
  sleep 1
done
echo "[entrypoint] Postgres is ready."

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
