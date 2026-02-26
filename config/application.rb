require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sunshine01
  class Application < Rails::Application
    config.load_defaults 8.0

    config.eager_load_paths += %W[
      #{root}/app/views
      #{root}/app/views/components
    ]

    config.active_record.query_log_tags_enabled = true
    # config.active_record.strict_loading_by_default = true
    config.active_record.use_yaml_unsafe_load = false
    config.active_record.yaml_column_permitted_classes = [
      Symbol,
      Date,
      Time,
      ActiveSupport::TimeWithZone,
      ActiveSupport::Duration
    ]
    config.active_support.to_time_preserves_timezone = :zone
    config.log_formatter = ::Logger::Formatter.new
    config.generators.system_tests = nil
    config.log_level = :debug
  end
end

require 'ostruct' # can remove if open struct usage is removed from the codebase