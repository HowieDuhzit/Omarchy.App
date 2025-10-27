class ApplicationController < ActionController::Base
  # CSRF Protection
  protect_from_forgery with: :exception
  
  # Security Headers
  before_action :set_security_headers
  
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
  end
end

