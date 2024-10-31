# frozen_string_literal: true

require "ddtrace"

module Datadog
  module BunnyTracer
    class ExchangeWrapper
      def initialize(exchange, service_name:)
        @exchange = exchange
        @service_name = service_name
      end

      def publish(payload, routing_key: "", **opts)
        Datadog::Tracing.trace("rabbitmq.publish", service: @service_name, resource: @exchange.name) do |span|
          # Ajouter des tags standards
          span.set_tag("messaging.system", "rabbitmq")
          span.set_tag("messaging.destination", @exchange.name)
          span.set_tag("messaging.destination_kind", "exchange")
          span.set_tag("messaging.routing_key", routing_key)

          # Injecter le contexte de trace
          trace_context = {
            "trace_id" => span.trace_id,
            "parent_id" => span.id
          }

          headers = (opts[:headers] || {}).merge(
            "x-datadog-trace-context" => trace_context.to_json
          )

          begin
            @exchange.publish(payload, routing_key: routing_key, **opts.merge(headers: headers))
          rescue StandardError => e
            span.set_error(e)
            raise
          end
        end
      end
    end
  end
end
