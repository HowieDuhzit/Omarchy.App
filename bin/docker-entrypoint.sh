#!/usr/bin/env bash
set -euo pipefail

: "${RAILS_ENV:=production}"

# Use DATABASE_URL if provided (Coolify magic variable)
if [ -n "${DATABASE_URL:-}" ]; then
  echo "[entrypoint] Using provided DATABASE_URL"
  export DATABASE_URL
else
  # Fallback to individual variables
  : "${PGHOST:=postgres}"
  : "${PGPORT:=5432}"
  : "${PGUSER:=postgres}"
  : "${PGPASSWORD:=password}"
  : "${PGDATABASE:=omarchy_directory_production}"
  
  export DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
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
