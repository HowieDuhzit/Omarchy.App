#!/bin/bash

# Omarchy Directory Production Deployment Script
# This script sets up the production environment with optimized Docker configuration

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

# Set default values
export RAILS_ENV=production
export APP_HOST=${APP_HOST:-omarchy.app}

# Create necessary directories
echo "📁 Creating production directories..."
sudo mkdir -p /opt/omarchy/{postgres_data,redis_data,app_logs,app_tmp,nginx_logs,backups}
sudo chown -R $USER:$USER /opt/omarchy

# Generate secret key base if not provided
if [ -z "$SECRET_KEY_BASE" ]; then
    echo "🔑 Generating SECRET_KEY_BASE..."
    export SECRET_KEY_BASE=$(openssl rand -hex 64)
fi

echo "📦 Building production Docker images..."
docker compose -f docker-compose.production.yml build --no-cache

echo "🗄️ Starting production services..."
docker compose -f docker-compose.production.yml up -d db redis

echo "⏳ Waiting for database to be ready..."
sleep 15

echo "🔧 Running database migrations..."
docker compose -f docker-compose.production.yml run --rm web bundle exec rails db:create db:migrate

echo "📊 Seeding database..."
docker compose -f docker-compose.production.yml run --rm web bundle exec rails db:seed

echo "🎨 Precompiling assets..."
docker compose -f docker-compose.production.yml run --rm web bundle exec rails assets:precompile

echo "🚀 Starting production services..."
docker compose -f docker-compose.production.yml up -d

echo "⏳ Waiting for services to be healthy..."
sleep 30

echo "✅ Production deployment completed!"
echo ""
echo "🌐 Application is running at: https://$APP_HOST"
echo "📊 Database: PostgreSQL on port 5432"
echo "🔄 Cache: Redis on port 6379"
echo "🌍 Web Server: Nginx on ports 80/443"
echo ""
echo "📝 Useful commands:"
echo "  View logs: docker compose -f docker-compose.production.yml logs -f"
echo "  Stop services: docker compose -f docker-compose.production.yml down"
echo "  Restart services: docker compose -f docker-compose.production.yml restart"
echo "  Database backup: docker compose -f docker-compose.production.yml exec db pg_dump -U postgres omarchy_directory_production > backup.sql"
echo ""
echo "🔒 Security reminders:"
echo "  - Change default admin password"
echo "  - Set up SSL certificates"
echo "  - Configure firewall rules"
echo "  - Set up monitoring and logging"
echo ""
echo "📊 Resource limits:"
echo "  Web app: 512MB RAM, 0.5 CPU"
echo "  Database: 1GB RAM, 1.0 CPU"
echo "  Redis: 256MB RAM, 0.25 CPU"
echo "  Nginx: 128MB RAM, 0.25 CPU"
