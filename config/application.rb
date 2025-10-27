require_relative "boot"

require "rails"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OmarchyDirectory
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = "UTC"

    # Only loads a smaller set of middleware suitable for API only apps.
    # We still render HTML views, so keep default stack.
  end
end

