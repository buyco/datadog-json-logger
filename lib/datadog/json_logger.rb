# frozen_string_literal: true

require "logger"
require_relative "loggers/version"
require_relative "loggers/json_formatter"

module Datadog
  class Error < StandardError; end

  class JSONLogger < Logger
    def initialize(output = nil)
      $stdout.sync = true
      super(output || $stdout)
      @default_formatter = ::Datadog::Loggers::JSONFormatter
    end
  end
end
