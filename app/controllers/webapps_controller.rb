class WebappsController < ApplicationController
  before_action :set_webapp, only: %i[ show edit update destroy install ]
  before_action :authenticate_admin!, only: %i[ update destroy ]
  before_action :set_admin_password
  skip_before_action :authenticate_admin!, only: [:authenticate_admin]
  skip_before_action :verify_authenticity_token, only: [:authenticate_admin, :destroy, :create]

  def index
    @webapps = Webapp.order(:name)
    
    # Apply filters and search
    @webapps = apply_search(@webapps) if params[:search].present?
    @webapps = apply_filter(@webapps) if params[:filter].present?
    @webapps = apply_sort(@webapps)
    
    # Add pagination for large datasets
    @webapps = @webapps.limit(100) if @webapps.count > 100
    
    respond_to do |format|
      format.html
      format.json { render json: { apps: @webapps.map(&:as_api), total: @webapps.count } }
    end
  end

  def install
    redirect_to @webapp.install_uri, allow_other_host: true
  end

  def show; end
  def new; @webapp = Webapp.new; end
  def edit; end

  def create
    @webapp = Webapp.new(webapp_params)
    
    if @webapp.save
      redirect_to root_path, notice: "App was successfully added."
    else
      redirect_to root_path, alert: "Failed to add app: #{@webapp.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @webapp.update(webapp_params)
      redirect_to @webapp, notice: "Webapp was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    app_name = @webapp.name
    @webapp.destroy!
    redirect_to root_path, notice: "#{app_name} was successfully deleted."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to root_path, alert: "Failed to delete app: #{e.message}"
  end

  def authenticate_admin
    admin_password = ENV['ADMIN_PASSWORD'] || 'omarchy2024'
    
    if params[:password] == admin_password
      session[:admin_authenticated] = true
      render json: { success: true, message: "Admin authenticated successfully" }
    else
      render json: { success: false, message: "Invalid password" }, status: :unauthorized
    end
  end

  private

  def set_webapp
    @webapp = Webapp.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "App not found."
  end

  def webapp_params
    params.require(:webapp).permit(:name, :url, :icon_url, :category)
  end

  def set_admin_password
    @admin_password = ENV['ADMIN_PASSWORD'] || 'omarchy2024'
  end

  def authenticate_admin!
    # Simple admin authentication based on session or params
    # In production, you'd want proper authentication
    admin_password = ENV['ADMIN_PASSWORD'] || 'omarchy2024'
    
    # Check if admin is authenticated via session or params
    unless session[:admin_authenticated] || params[:admin_password] == admin_password
      redirect_to root_path, alert: "Admin access required"
      return false
    end
    
    # Set session for future requests
    session[:admin_authenticated] = true
    true
  end

  def apply_search(webapps)
    search_term = params[:search].strip
    webapps.where("name ILIKE ? OR category ILIKE ?", "%#{search_term}%", "%#{search_term}%")
  end

  def apply_filter(webapps)
    webapps.where(category: params[:filter])
  end

  def apply_sort(webapps)
    case params[:sort]
    when 'name_desc'
      webapps.order(name: :desc)
    when 'created_at'
      webapps.order(created_at: :desc)
    when 'created_at_desc'
      webapps.order(created_at: :asc)
    else
      webapps.order(:name)
    end
  end
end
