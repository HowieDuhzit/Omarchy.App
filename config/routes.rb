Rails.application.routes.draw do
  root "webapps#index"

  resources :webapps do
    member { get :install }
  end

  # Admin authentication endpoint
  post "/admin/authenticate", to: "webapps#authenticate_admin"
  
  get "/setup", to: "pages#setup"
  
  # Health check endpoint for Coolify
  get '/health', to: 'application#health'
  
  # Debug endpoints (only in development)
  if Rails.env.development?
    get '/debug', to: 'debug#index'
    get '/debug/error', to: 'debug#error_test'
  end
  
  # API endpoint
  get '/webapps.json', to: 'webapps#index', defaults: { format: :json }
  
  # Error pages
  get '/404', to: 'errors#not_found'
  get '/500', to: 'errors#internal_server_error'
  get '/422', to: 'errors#unprocessable_entity'
end

