#!/usr/bin/env bash
set -euo pipefail

: "${RAILS_ENV:=production}"

echo "[entrypoint] DATABASE_URL: ${DATABASE_URL:-NOT_SET}"
echo "[entrypoint] SERVICE_URL_POSTGRES: ${SERVICE_URL_POSTGRES:-NOT_SET}"
echo "[entrypoint] SERVICE_PASSWORD_POSTGRES: ${SERVICE_PASSWORD_POSTGRES:-NOT_SET}"

# Check if we're using PostgreSQL or SQLite
if [ -n "${DATABASE_URL:-}" ] && [[ "${DATABASE_URL}" =~ ^postgresql:// ]]; then
  echo "[entrypoint] Using PostgreSQL database"
  # Construct proper PostgreSQL connection string for internal use
  if [ -n "${SERVICE_PASSWORD_POSTGRES:-}" ]; then
    echo "[entrypoint] Using internal PostgreSQL connection"
    export DATABASE_URL="postgresql://postgres:${SERVICE_PASSWORD_POSTGRES}@postgres:5432/omarchy_directory_production"
  fi

  echo "[entrypoint] Final DATABASE_URL: ${DATABASE_URL}"

  echo "[entrypoint] Checking gems..."
  bundle check

  echo "[entrypoint] Ensuring log directory is writable..."
  touch /app/log/development.log 2>/dev/null || true
  chmod 666 /app/log/development.log 2>/dev/null || true

  echo "[entrypoint] Waiting for PostgreSQL to be ready..."
  until pg_isready -h postgres -p 5432 -U postgres >/dev/null 2>&1; do
    echo "[entrypoint] Waiting for PostgreSQL..."
    sleep 2
  done
  echo "[entrypoint] PostgreSQL is ready!"
else
  echo "[entrypoint] Using SQLite database"
  echo "[entrypoint] DATABASE_URL: ${DATABASE_URL:-NOT_SET}"

  echo "[entrypoint] Checking gems..."
  bundle check

  echo "[entrypoint] Ensuring log directory is writable..."
  touch /app/log/development.log 2>/dev/null || true
  chmod 666 /app/log/development.log 2>/dev/null || true

  # For SQLite, we don't need to wait for a database server
  echo "[entrypoint] SQLite database ready!"
fi

echo "[entrypoint] Preparing database..."
# Ensure binstubs are executable when bind-mounted from host
chmod +x bin/rails bin/rake || true
bin/rails db:prepare

echo "[entrypoint] Seeding database..."
bin/rails db:seed

echo "[entrypoint] Starting: $*"
# Run Rails server without PID file to avoid permission issues
if [[ "$*" == *"rails server"* ]]; then
  exec bundle exec rails server -b 0.0.0.0 -p 3000 --pid /dev/null
else
  exec "$@"
fi
