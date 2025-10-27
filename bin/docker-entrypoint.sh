#!/usr/bin/env bash
set -euo pipefail

: "${RAILS_ENV:=development}"
: "${PGHOST:=db}"
: "${PGPORT:=5432}"
: "${PGUSER:=omarchy}"
: "${PGPASSWORD:=omarchy}"
: "${PGDATABASE:=omarchy_directory_development}"
export RAILS_ENV PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE

echo "[entrypoint] Waiting for Postgres at ${PGHOST}:${PGPORT}..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" >/dev/null 2>&1; do
  sleep 1
done
echo "[entrypoint] Postgres is ready."

echo "[entrypoint] Installing gems if needed..."
bundle check || bundle install

echo "[entrypoint] Preparing database..."
# Ensure binstubs are executable when bind-mounted from host
chmod +x bin/rails bin/rake || true
bin/rails db:prepare

echo "[entrypoint] Seeding database..."
bin/rails db:seed

echo "[entrypoint] Starting: $*"
exec "$@"
