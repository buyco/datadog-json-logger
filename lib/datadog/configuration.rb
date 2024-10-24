# frozen_string_literal: true

module Datadog
  class Configuration
    attr_accessor :current_user, :controller_key, :resource_key, :action_key

    # @param current_user [Lambda] A lambda that returns the current user
    # e.g. ->(env) { env["current_user"] }

    # @return [Datadog::Configuration]
    def initialize
      @current_user   = nil
      @controller_key = "sinatra.controller_name"
      @resource_key   = "sinatra.resource_name"
      @action_key     = "sinatra.action_name"
    end

    def log_current_user?
      @current_user ? true : false
    end
  end
end
