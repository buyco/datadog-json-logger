# frozen_string_literal: true

require "ddtrace"
require "logger"
require "json"

module Datadog
  module Loggers
    class Formatter < Logger::Formatter
      def self.call(severity, datetime, progname, msg)
        log_hash = {
          dd: correlation_hash,
          timestamp: datetime.to_s,
          severity: severity.ljust(5).to_s,
          progname: progname.to_s
        }

        if msg.is_a?(Hash) && msg.key?(:request)
          log_hash.merge!(msg)
        elsif msg.is_a?(Exception)
          log_hash.merge!(
            exception: msg,
            exception_message: msg.message,
            exception_backtrace: msg.backtrace
          )
        elsif msg.instance_of?(String)
          log_hash[:message] = msg.dup.force_encoding("utf-8")
        else
          log_hash[:message] = msg.to_s
        end

        log_hash.to_json + "\r\n" # rubocop:disable Style/StringConcatenation
      end

      def self.correlation_hash
        correlation = Datadog::Tracing.correlation

        {
          trace_id: correlation.trace_id&.to_s,
          span_id: correlation.span_id&.to_s,
          env: correlation.env&.to_s,
          service: correlation.service&.to_s,
          version: correlation.version&.to_s
        }
      end
    end
  end
end
