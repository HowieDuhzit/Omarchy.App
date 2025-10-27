class ErrorsController < ApplicationController
  # Skip CSRF protection for error pages
  skip_before_action :verify_authenticity_token
  
  def not_found
    render '404', status: 404
  end
  
  def internal_server_error
    render '500', status: 500
  end
  
  def unprocessable_entity
    render '422', status: 422
  end
end
