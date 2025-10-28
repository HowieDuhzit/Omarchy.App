# Security Configuration for Omarchy Directory
# This file contains security-related settings and recommendations

# Application Security Configuration
class ApplicationController < ActionController::Base
  # CSRF Protection
  protect_from_forgery with: :exception
  
  # Security Headers
  before_action :set_security_headers
  
  # Rate Limiting
  before_action :check_rate_limit, only: [:create, :update, :destroy]
  
  private
  
  def set_security_headers
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
  end
  
  def check_rate_limit
    # Simple rate limiting - in production, use Redis-based rate limiting
    session_key = "rate_limit_#{request.remote_ip}_#{Time.current.strftime('%Y%m%d%H%M')}"
    
    if session[session_key].to_i > 10 # Max 10 requests per minute
      render json: { error: 'Rate limit exceeded' }, status: 429
      return
    end
    
    session[session_key] = (session[session_key] || 0) + 1
  end
end

# Content Security Policy Configuration
# Add to config/application.rb or config/environments/production.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "https://omarchy.org"
    policy.object_src  :none
    policy.script_src  :self, :https, "https://cdn.tailwindcss.com"
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https, "https://api.allorigins.win"
    policy.frame_ancestors :none
    policy.base_uri :self
  end
  
  # Configure CSP reporting
  config.content_security_policy_report_only = false
end

# Database Security
# Add to config/database.yml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  url: <%= ENV['DATABASE_URL'] %>
  sslmode: require
  sslcert: <%= ENV['DB_SSL_CERT'] if ENV['DB_SSL_CERT'] %>
  sslkey: <%= ENV['DB_SSL_KEY'] if ENV['DB_SSL_KEY'] %>
  sslrootcert: <%= ENV['DB_SSL_ROOT_CERT'] if ENV['DB_SSL_ROOT_CERT'] %>

# Session Security
# Add to config/application.rb
Rails.application.configure do
  config.session_store = :redis_store, {
    servers: [{ host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: 1 }],
    expire_after: 1.week,
    key: '_omarchy_directory_session',
    secure: true,
    httponly: true,
    same_site: :strict
  }
end

# Input Validation and Sanitization
# Add to app/models/webapp.rb
class Webapp < ApplicationRecord
  # Additional security validations
  validates :name, length: { maximum: 100 }, format: { without: /<script|javascript:|data:/i }
  validates :url, format: { with: /\Ahttps?:\/\/.+\z/, message: "must be a valid HTTP/HTTPS URL" }
  validates :icon_url, format: { with: /\Ahttps?:\/\/.+\z/, message: "must be a valid HTTP/HTTPS URL" }
  
  # Sanitize inputs
  before_validation :sanitize_inputs
  
  private
  
  def sanitize_inputs
    self.name = ActionController::Base.helpers.sanitize(name) if name.present?
    self.url = url.strip.downcase if url.present?
    self.icon_url = icon_url.strip.downcase if icon_url.present?
  end
end

# Admin Authentication Security
# Add to app/controllers/webapps_controller.rb
class WebappsController < ApplicationController
  before_action :authenticate_admin!, only: [:create, :update, :destroy]
  
  private
  
  def authenticate_admin!
    # In production, implement proper authentication
    # For now, we rely on frontend admin mode with environment variable
    admin_password = ENV['ADMIN_PASSWORD']
    
    unless admin_password.present? && admin_password.length >= 12
      Rails.logger.warn "Admin password is not properly configured"
      redirect_to root_path, alert: "Admin access not available"
    end
  end
end

# Logging Security Events
# Add to config/application.rb
Rails.application.configure do
  # Log security events
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  
  # Custom log format for security
  config.lograge.custom_payload do |controller|
    {
      user_agent: controller.request.user_agent,
      remote_ip: controller.request.remote_ip,
      referer: controller.request.referer,
      admin_action: controller.action_name.in?(%w[create update destroy])
    }
  end
end


