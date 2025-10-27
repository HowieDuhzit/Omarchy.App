Rails.application.configure do
  # Force SSL in production (can be overridden by RAILS_FORCE_SSL env var)
  config.force_ssl = ENV.fetch('RAILS_FORCE_SSL', 'true') == 'true'

  # Use simple memory cache store (no Redis needed)
  config.cache_store = :memory_store

  # Enable asset compilation
  config.assets.compile = false
  config.assets.digest = true
  config.assets.enabled = true

  # Logging configuration - enable debug logging for troubleshooting
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info').to_sym
  config.log_formatter = ::Logger::Formatter.new

  # Performance optimizations
  config.eager_load = true
  config.cache_classes = true

  # Database connection pool - simple configuration for single database
  config.active_record.database_selector = nil
  config.active_record.database_resolver = nil
  config.active_record.database_resolver_context = nil
  
  # Disable SQLite production warning since we're intentionally using SQLite
  config.active_record.sqlite3_production_warning = false

  # Content Security Policy
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "https://omarchy.app", "https://omarchy.org"
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, "https://cdn.tailwindcss.com"
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https, "https://api.allorigins.win"
    policy.frame_src   :none
    policy.base_uri    :self
  end

  # Configure CSP reporting
  config.content_security_policy_report_only = false

  # Session configuration
  config.session_store :cookie_store, key: '_omarchy_directory_session', secure: true, httponly: true, same_site: :lax
end