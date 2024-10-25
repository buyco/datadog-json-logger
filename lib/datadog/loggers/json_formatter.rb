# frozen_string_literal: true

require "ddtrace"
require "json"
require "logger"

module Datadog
  module Loggers
    class JSONFormatter < Logger::Formatter
      def self.call(severity, datetime, progname, msg)
        log_hash = base_log_hash(severity, datetime, progname)
        formatter = formatter_for(msg)
        formatter.format(log_hash, msg)

        yield(log_hash) if block_given?

        "#{::JSON.dump(log_hash)}\n"
      end

      def self.base_log_hash(severity, datetime, progname)
        {
          dd: correlation_hash,
          timestamp: datetime.to_s,
          severity: severity.ljust(5).to_s,
          progname: progname.to_s,
          **custom_context
        }
      end

      def self.custom_context
        context = Datadog::JSONLogger.config.custom_context
        return {} unless context.respond_to?(:call)

        context.call
      end

      def self.formatter_for(msg)
        case msg
        when Hash then HashFormatter
        when Exception then ExceptionFormatter
        when String then StringFormatter
        when Proc then ProcFormatter
        else DefaultFormatter
        end
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

      module HashFormatter
        module_function

        def format(log_hash, msg)
          log_hash.merge!(msg)
        end
      end

      module ExceptionFormatter
        module_function

        def format(log_hash, exception)
          log_hash.merge!(
            message: exception.inspect,
            error: {
              kind: exception.class,
              message: exception.message,
              stack: (exception.backtrace || []).join("\n")
            }
          )
        end
      end

      module StringFormatter
        module_function

        def format(log_hash, msg)
          log_hash[:message] = msg.dup.force_encoding("utf-8")
        end
      end

      module ProcFormatter
        module_function

        def format(log_hash, msg)
          log_hash[:message] = msg.call
        end
      end

      module DefaultFormatter
        module_function

        def format(log_hash, msg)
          log_hash[:message] = msg.is_a?(String) ? msg : msg.inspect
        end
      end
    end
  end
end
