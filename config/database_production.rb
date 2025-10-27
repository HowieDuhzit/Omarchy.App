# Production Database Configuration
# This file contains production database settings and optimizations

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
  
  # Connection pool settings
  checkout_timeout: 5
  reaping_frequency: 10
  idle_timeout: 300
  
  # Query optimization
  prepared_statements: true
  advisory_locks: true
  
  # Logging
  log_level: :info
  log_statement: :none

# Add to config/application.rb
Rails.application.configure do
  # Database connection pool
  config.active_record.database_selector = { delay: 2.seconds }
  config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
  
  # Connection pool settings
  config.active_record.connection_pool_size = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
  config.active_record.checkout_timeout = 5
  config.active_record.reaping_frequency = 10
  config.active_record.idle_timeout = 300
  
  # Query optimization
  config.active_record.prepared_statements = true
  config.active_record.advisory_locks = true
  
  # Logging
  config.active_record.logger = nil # Disable SQL logging in production
  config.active_record.log_level = :info
end

# Add to app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  # Connection management
  connects_to database: { writing: :primary, reading: :primary }
  
  # Query optimization
  self.abstract_class = true
  
  # Default scopes for performance
  default_scope { where(deleted_at: nil) } if column_names.include?('deleted_at')
end

# Add to app/models/webapp.rb
class Webapp < ApplicationRecord
  # Database indexes for performance
  # Add these via migration:
  # add_index :webapps, :name
  # add_index :webapps, :category
  # add_index :webapps, :created_at
  # add_index :webapps, [:category, :name]
  
  # Query optimization
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :search_by_name, ->(term) { where("name ILIKE ?", "%#{term}%") }
  
  # Caching
  def self.cached_all
    Rails.cache.fetch("webapps_all", expires_in: 1.hour) do
      all.to_a
    end
  end
  
  def self.cached_by_category(category)
    Rails.cache.fetch("webapps_category_#{category}", expires_in: 1.hour) do
      by_category(category).to_a
    end
  end
  
  # Cache invalidation
  after_save :invalidate_cache
  after_destroy :invalidate_cache
  
  private
  
  def invalidate_cache
    Rails.cache.delete("webapps_all")
    Rails.cache.delete("webapps_category_#{category}")
  end
end

# Add to config/initializers/database.rb
Rails.application.configure do
  # Database connection monitoring
  config.active_record.connection_pool_size = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
  
  # Connection health checks
  config.active_record.connection_pool.checkout_timeout = 5
  config.active_record.connection_pool.reaping_frequency = 10
  config.active_record.connection_pool.idle_timeout = 300
  
  # Query optimization
  config.active_record.prepared_statements = true
  config.active_record.advisory_locks = true
  
  # Logging configuration
  config.active_record.logger = nil # Disable SQL logging in production
  config.active_record.log_level = :info
end

# Add to config/initializers/connection_monitoring.rb
Rails.application.configure do
  # Database connection monitoring
  config.after_initialize do
    ActiveRecord::Base.connection_pool.after_fork do
      ActiveRecord::Base.establish_connection
    end
  end
  
  # Connection health checks
  config.active_record.connection_pool.checkout_timeout = 5
  config.active_record.connection_pool.reaping_frequency = 10
  config.active_record.connection_pool.idle_timeout = 300
end

# Add to config/initializers/database_backup.rb
Rails.application.configure do
  # Database backup configuration
  config.after_initialize do
    # Schedule daily backups (if using a job scheduler)
    # DailyBackupJob.perform_later if defined?(DailyBackupJob)
  end
end

# Add to lib/tasks/database.rake
namespace :db do
  desc "Backup database"
  task backup: :environment do
    database = Rails.configuration.database_configuration[Rails.env]
    backup_file = "backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
    backup_path = Rails.root.join('backups', backup_file)
    
    system("pg_dump -h #{database['host']} -U #{database['username']} -d #{database['database']} > #{backup_path}")
    puts "Database backed up to #{backup_path}"
  end
  
  desc "Restore database from backup"
  task :restore, [:backup_file] => :environment do |t, args|
    database = Rails.configuration.database_configuration[Rails.env]
    backup_path = Rails.root.join('backups', args[:backup_file])
    
    if File.exist?(backup_path)
      system("psql -h #{database['host']} -U #{database['username']} -d #{database['database']} < #{backup_path}")
      puts "Database restored from #{backup_path}"
    else
      puts "Backup file not found: #{backup_path}"
    end
  end
  
  desc "Optimize database"
  task optimize: :environment do
    ActiveRecord::Base.connection.execute("VACUUM ANALYZE;")
    puts "Database optimized"
  end
end

