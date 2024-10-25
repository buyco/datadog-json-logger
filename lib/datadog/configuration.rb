# frozen_string_literal: true

module Datadog
  class Configuration
    attr_accessor :current_user, :custom_context, :controller_key, :resource_key, :action_key

    # @param current_user [Lambda] A lambda that returns the current user
    # e.g. ->(env) { env["current_user"] }
    # @param custom_context [Proc] A proc that returns a hash of custom context
    # @param controller_key [String] The key to use for the controller name in the log
    # @param resource_key [String] The key to use for the resource name in the log
    # @param action_key [String] The key to use for the action name in the log

    # @return [Datadog::Configuration]
    def initialize
      @current_user   = nil
      @custom_context = -> { {} }
      @controller_key = "sinatra.controller_name"
      @resource_key   = "sinatra.resource_name"
      @action_key     = "sinatra.action_name"
    end

    def log_current_user?
      @current_user ? true : false
    end
  end
end
