# frozen_string_literal: true

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

    def initialize(app, logger)
      @app    = app
      @logger = logger
    end

    def call(env)
      request               = Rack::Request.new(env)
      params_array          = URI.decode_www_form(request.query_string)
      start_time            = Time.now
      status, headers, body = app.call(env)
      end_time              = Time.now

      logger.info(
        request: true,
        request_ip: request.ip.to_s,
        method: request.request_method.to_s,
        controller: env["sinatra.controller_name"],
        action: env["sinatra.action_name"],
        path: request.path.to_s,
        params: params_array.to_h,
        status: status,
        format: headers["Content-Type"],
        duration: (end_time - start_time).to_i
      )

      [status, headers, body]
    end
  end
end
