# Production Error Handling and Logging Configuration
# This file contains error handling and logging configurations for production

# Add to config/application.rb
Rails.application.configure do
  # Error handling
  config.exceptions_app = self.routes
  
  # Logging configuration
  config.log_level = :info
  config.log_formatter = ::Logger::Formatter.new
  
  # Structured logging for production
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  
  # Custom log format for security and performance
  config.lograge.custom_payload do |controller|
    {
      user_agent: controller.request.user_agent,
      remote_ip: controller.request.remote_ip,
      referer: controller.request.referer,
      admin_action: controller.action_name.in?(%w[create update destroy]),
      response_time: controller.request.env['lograge.response_time'],
      memory_usage: `ps -o rss= -p #{Process.pid}`.to_i / 1024 # MB
    }
  end
  
  # Error tracking (uncomment and configure as needed)
  # config.filter_parameters += [:password, :admin_password, :secret_key_base]
end

# Add to app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from StandardError, with: :handle_error
  
  # Logging
  before_action :log_request
  after_action :log_response
  
  private
  
  def record_not_found(exception)
    Rails.logger.warn "Record not found: #{exception.message}"
    redirect_to root_path, alert: "The requested resource was not found."
  end
  
  def parameter_missing(exception)
    Rails.logger.warn "Parameter missing: #{exception.message}"
    redirect_to root_path, alert: "Required parameters are missing."
  end
  
  def handle_error(exception)
    Rails.logger.error "Unhandled error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    # In production, you might want to send this to an error tracking service
    # Sentry.capture_exception(exception) if defined?(Sentry)
    
    redirect_to root_path, alert: "An unexpected error occurred. Please try again."
  end
  
  def log_request
    @request_start_time = Time.current
    Rails.logger.info "Request started: #{request.method} #{request.path} from #{request.remote_ip}"
  end
  
  def log_response
    duration = Time.current - @request_start_time
    Rails.logger.info "Request completed: #{response.status} in #{duration.round(3)}s"
  end
end

# Add to app/controllers/webapps_controller.rb
class WebappsController < ApplicationController
  # Additional error handling for webapp-specific actions
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
  
  private
  
  def handle_validation_error(exception)
    Rails.logger.warn "Validation error: #{exception.message}"
    redirect_to root_path, alert: "Invalid data provided: #{exception.message}"
  end
  
  def handle_csrf_error(exception)
    Rails.logger.warn "CSRF token error: #{exception.message}"
    redirect_to root_path, alert: "Security token expired. Please try again."
  end
end

# Add to config/initializers/logging.rb
Rails.application.configure do
  # Custom logger for different log levels
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.logger.level = Logger::INFO
  
  # Separate log files for different purposes
  config.logger = ActiveSupport::Logger.new(Rails.root.join('log', 'production.log'))
  
  # Log rotation
  config.logger = ActiveSupport::Logger.new(
    Rails.root.join('log', 'production.log'),
    10, # Keep 10 log files
    100.megabytes # Max 100MB per file
  )
end

# Add to config/initializers/error_tracking.rb (optional)
# Uncomment and configure based on your error tracking service

# Sentry configuration
# Sentry.init do |config|
#   config.dsn = ENV['SENTRY_DSN']
#   config.breadcrumbs_logger = [:active_support_logger, :http_logger]
#   config.traces_sample_rate = 0.1
#   config.profiles_sample_rate = 0.1
# end

# New Relic configuration
# if defined?(NewRelic)
#   NewRelic::Agent.manual_start(
#     :license_key => ENV['NEW_RELIC_LICENSE_KEY'],
#     :app_name => 'Omarchy Directory',
#     :log => 'log/newrelic.log'
#   )
# end

# Custom error pages
# Create app/views/errors/404.html.erb
# Create app/views/errors/500.html.erb
# Create app/views/errors/422.html.erb

# Add to config/application.rb
Rails.application.configure do
  # Custom error pages
  config.exceptions_app = self.routes
end

# Add to config/routes.rb
Rails.application.routes.draw do
  # Error pages
  get '/404', to: 'errors#not_found'
  get '/500', to: 'errors#internal_server_error'
  get '/422', to: 'errors#unprocessable_entity'
end

# Create app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  def not_found
    render status: 404
  end
  
  def internal_server_error
    render status: 500
  end
  
  def unprocessable_entity
    render status: 422
  end
end





