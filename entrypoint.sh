#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Starting Omarchy Apps..."

# Always override DATABASE_URL to ensure correct protocol and connection
echo "[entrypoint] Overriding DATABASE_URL to ensure correct postgresql:// protocol..."
if [ -n "${SERVICE_PASSWORD_POSTGRES:-}" ]; then
  export DATABASE_URL="postgresql://postgres:${SERVICE_PASSWORD_POSTGRES}@postgres:5432/omarchy_directory_production"
  echo "[entrypoint] Using constructed DATABASE_URL with SERVICE_PASSWORD_POSTGRES"
else
  echo "[entrypoint] No SERVICE_PASSWORD_POSTGRES found, using default connection"
  export DATABASE_URL="postgresql://postgres:password@postgres:5432/omarchy_directory_production"
fi

echo "[entrypoint] DATABASE_URL: ${DATABASE_URL}"

# Wait for PostgreSQL to be ready
echo "[entrypoint] Waiting for PostgreSQL to be ready..."
until pg_isready -h postgres -p 5432 -U postgres >/dev/null 2>&1; do
  echo "[entrypoint] Waiting for PostgreSQL..."
  sleep 2
done
echo "[entrypoint] PostgreSQL is ready!"

# Run database migrations
echo "[entrypoint] Running database migrations..."
bundle exec rails db:migrate

# Seed the database
echo "[entrypoint] Seeding database..."
bundle exec rails db:seed

# Start the Rails server
echo "[entrypoint] Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p 3000
