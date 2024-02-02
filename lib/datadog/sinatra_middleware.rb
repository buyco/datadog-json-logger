# frozen_string_literal: true

require "json"
require "uri"

module Rack
  class CommonLogger
    def log(_env, _status, _response_headers, _began_at)
      # Disable default rack logger output
      nil
    end
  end
end

module Datadog
  class SinatraMiddleware
    attr_reader :app, :logger

    def initialize(app, logger, opt = {})
      @app = app
      @logger = logger
      @raise_exceptions = opt.fetch(:raise_exceptions, false)
    end

    def call(env)
      request = Rack::Request.new(env)
      start_time = Time.now

      status, headers, body = if @raise_exceptions
                                app.call(env)
                              else
                                safely_process_request(env)
                              end
      end_time = Time.now

      log_request(request, env, status, headers, start_time, end_time)

      [status, headers, body]
    rescue StandardError => e
      handle_exception(e)
    end

    private

    def safely_process_request(env)
      app.call(env)
    rescue StandardError => e
      [500, { "Content-Type": "application/json" }, [e.class.name, e.message].join(": ")]
    end

    def log_request(request, env, status, headers, start_time, end_time)
      log_data = {
        request: true,
        request_ip: request.ip,
        method: request.request_method,
        controller: env["sinatra.controller_name"],
        resource: env["sinatra.resource_name"] || env["sinatra.controller_name"],
        action: env["sinatra.action_name"],
        path: request.path,
        params: parse_query(request.query_string),
        status: status,
        format: headers["Content-Type"],
        duration: calculate_duration(start_time, end_time)
      }

      log_data[:message] = message(log_data)

      logger.info(log_data)
    end

    def message(log_data)
      "Received #{log_data[:method]} request from #{log_data[:request_ip]} " \
        "to #{log_data[:controller]}##{log_data[:action]} at #{log_data[:path]} " \
        "with params #{log_data[:params].to_json}. Responded with status #{log_data[:status]} " \
        "in #{log_data[:duration]}ms. Content-Type: #{log_data[:format]}."
    end

    def calculate_duration(start_time, end_time)
      ((end_time - start_time) * 1000).round # Duration in milliseconds
    end

    def parse_query(query_string)
      URI.decode_www_form(query_string).to_h
    end

    def handle_exception(exception)
      logger.error(
        exception: exception.class.name,
        exception_message: exception.message,
        exception_backtrace: exception.backtrace
      )

      raise(exception)
    end
  end
end
