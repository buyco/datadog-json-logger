# frozen_string_literal: true

require "logger"
require_relative "loggers/json_formatter"
require_relative "loggers/version"

module Datadog
  class Error < StandardError; end

  class JSONLogger < Logger
    def initialize(output = default_output)
      super(output)
      @default_formatter = ::Datadog::Loggers::JSONFormatter
    end

    private

    def default_output
      $stdout.sync = true
      $stdout
    end
  end
end
