#!/bin/bash

# Omarchy Directory Production Deployment Script
# This script sets up the production environment

set -e

echo "🚀 Starting Omarchy Directory Production Deployment..."

# Check if required environment variables are set
required_vars=("POSTGRES_PASSWORD" "SECRET_KEY_BASE" "ADMIN_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var environment variable is not set"
        echo "Please set the following environment variables:"
        echo "  POSTGRES_PASSWORD - Database password"
        echo "  SECRET_KEY_BASE - Rails secret key base"
        echo "  ADMIN_PASSWORD - Admin password for the application"
        exit 1
    fi
done

# Generate secret key base if not provided
if [ -z "$SECRET_KEY_BASE" ]; then
    echo "🔑 Generating SECRET_KEY_BASE..."
    export SECRET_KEY_BASE=$(bundle exec rails secret)
fi

# Set default values
export RAILS_ENV=production
export APP_HOST=${APP_HOST:-omarchy.app}
export REDIS_URL=${REDIS_URL:-redis://redis:6379/0}

echo "📦 Building production Docker images..."
docker compose -f docker-compose.prod.yml build

echo "🗄️ Starting production services..."
docker compose -f docker-compose.prod.yml up -d db redis

echo "⏳ Waiting for database to be ready..."
sleep 10

echo "🔧 Running database migrations..."
docker compose -f docker-compose.prod.yml run --rm web bundle exec rails db:create db:migrate

echo "📊 Seeding database..."
docker compose -f docker-compose.prod.yml run --rm web bundle exec rails db:seed

echo "🎨 Precompiling assets..."
docker compose -f docker-compose.prod.yml run --rm web bundle exec rails assets:precompile

echo "🚀 Starting production services..."
docker compose -f docker-compose.prod.yml up -d

echo "✅ Production deployment completed!"
echo ""
echo "🌐 Application is running at: https://$APP_HOST"
echo "📊 Database: PostgreSQL on port 5432"
echo "🔄 Cache: Redis on port 6379"
echo "🌍 Web Server: Nginx on ports 80/443"
echo ""
echo "📝 Useful commands:"
echo "  View logs: docker compose -f docker-compose.prod.yml logs -f"
echo "  Stop services: docker compose -f docker-compose.prod.yml down"
echo "  Restart services: docker compose -f docker-compose.prod.yml restart"
echo "  Database backup: docker compose -f docker-compose.prod.yml exec db pg_dump -U postgres omarchy_directory_production > backup.sql"
echo ""
echo "🔒 Security reminders:"
echo "  - Change default admin password"
echo "  - Set up SSL certificates"
echo "  - Configure firewall rules"
echo "  - Set up monitoring and logging"
