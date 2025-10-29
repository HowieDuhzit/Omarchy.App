# Multi-stage build optimized for production deployment
FROM ruby:3.2-slim AS base

# Install system dependencies
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
    build-essential \
    libyaml-dev \
    git \
    curl \
    bash \
    nodejs \
    npm \
    ca-certificates \
    redis-tools \
    libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# Set working directory
WORKDIR /app

# Configure bundler for production
ENV BUNDLE_PATH=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_WITHOUT="development test" \
    RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# Development stage
FROM base AS development
ENV BUNDLE_WITHOUT=""
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
RUN mkdir -p tmp/pids log public/assets db
RUN chmod +x bin/rails bin/rake || true
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

# Build stage
FROM base AS build

# Copy Gemfile and install production gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Production stage
FROM ruby:3.2-slim AS production

# Install runtime dependencies and build tools for native extensions
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    redis-tools \
    build-essential \
    libyaml-dev \
    libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# Set working directory
WORKDIR /app

# Configure bundler for production
ENV BUNDLE_PATH=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_WITHOUT="development test" \
    RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# Copy Gemfile and install production gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Copy application code
COPY --from=build /app .

# Create necessary directories
RUN mkdir -p tmp/pids log public/assets db

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy entrypoint script and set permissions (before switching to non-root user)
COPY bin/docker-entrypoint.sh /usr/bin/docker-entrypoint
RUN chmod +x /usr/bin/docker-entrypoint

# Set proper permissions for directories
RUN chown -R appuser:appuser /app
RUN chmod -R 755 /app/tmp /app/log /app/db

# Switch to non-root user
USER appuser

# Health check for production
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

ENTRYPOINT ["docker-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

