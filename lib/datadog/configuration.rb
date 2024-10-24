# frozen_string_literal: true

module Datadog
  class Configuration
    attr_accessor :current_user

    # @param current_user [Lambda] A lambda that returns the current user
    # e.g. ->(env) { env["current_user"] }

    # @return [Datadog::Configuration]
    def initialize
      @current_user = nil
    end

    def log_current_user?
      @current_user
    end
  end
end
