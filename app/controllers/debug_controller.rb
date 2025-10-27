class DebugController < ApplicationController
  # Skip CSRF protection for debugging
  skip_before_action :verify_authenticity_token
  
  def index
    render json: {
      status: 'ok',
      environment: Rails.env,
      database_url: ENV['DATABASE_URL'] ? 'set' : 'not set',
      secret_key_base: ENV['SECRET_KEY_BASE'] ? 'set' : 'not set',
      admin_password: ENV['ADMIN_PASSWORD'] ? 'set' : 'not set',
      app_host: ENV['APP_HOST'] || 'not set',
      rails_force_ssl: ENV['RAILS_FORCE_SSL'] || 'not set',
      database_connected: database_connected?,
      webapp_count: Webapp.count,
      timestamp: Time.current
    }
  end
  
  def error_test
    # Test if we can trigger an error intentionally
    begin
      Webapp.first
      render json: { status: 'ok', message: 'Database query successful' }
    rescue => e
      render json: { 
        status: 'error', 
        error: e.message, 
        backtrace: e.backtrace.first(5) 
      }
    end
  end
  
  private
  
  def database_connected?
    ActiveRecord::Base.connection.active?
  rescue
    false
  end
end
