Rails.application.configure do
  # Force SSL in production
  config.force_ssl = true

  # Use production cache store
  config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }

  # Enable asset compilation
  config.assets.compile = false
  config.assets.digest = true
  config.assets.enabled = true

  # Logging configuration
  config.log_level = :info
  config.log_formatter = ::Logger::Formatter.new

  # Performance optimizations
  config.eager_load = true
  config.cache_classes = true

  # Security headers
  config.force_ssl = true

  # Database connection pool
  config.active_record.database_selector = { delay: 2.seconds }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  # Content Security Policy
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "https://omarchy.org"
    policy.object_src  :none
    policy.script_src  :self, :https, "https://cdn.tailwindcss.com"
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https, "https://api.allorigins.win"
  end

  # Configure CSP reporting
  config.content_security_policy_report_only = false

  # Session configuration
  config.session_store = :redis_store, {
    servers: [{ host: ENV['REDIS_HOST'] || 'localhost', port: ENV['REDIS_PORT'] || 6379, db: 1 }],
    expire_after: 1.week,
    key: '_omarchy_directory_session',
    secure: true,
    httponly: true
  }
end