class ApplicationController < ActionController::Base
  # CSRF Protection
  protect_from_forgery with: :exception
  
  # Security Headers
  before_action :set_security_headers
  
  # Error handling
  rescue_from StandardError, with: :handle_error
  
  # Health check endpoint for Coolify
  def health
    render plain: "healthy", status: :ok
  end
  
  private
  
  def set_security_headers
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains' if request.ssl?
  end
  
  def handle_error(exception)
    Rails.logger.error "Application Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    if Rails.env.production?
      render json: { 
        error: 'Internal Server Error', 
        timestamp: Time.current
      }, status: :internal_server_error
    else
      raise exception
    end
  end
end

