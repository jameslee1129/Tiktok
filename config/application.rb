require_relative "boot"

# Only require what we need for API-only app with MongoDB (no ActiveRecord)
require "rails"
require "active_model/railtie"
# ActiveJob excluded - it requires ActiveRecord
# require "active_job/railtie"
# ActiveRecord excluded - using MongoDB/Mongoid instead
# require "active_record/railtie"
require "action_controller/railtie"
# ActionMailer excluded - not needed for API
# require "action_mailer/railtie"
# ActionView excluded - not needed for API-only
# require "action_view/railtie"
# ActionCable excluded - not needed for API
# require "action_cable/engine"

require "mongoid"

Bundler.require(*Rails.groups)

module TikTokShopScraper
  class Application < Rails::Application
    config.load_defaults 7.0
    config.api_only = true
  end
end

