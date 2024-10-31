# frozen_string_literal: true

require "ddtrace"

module Datadog
  module BunnyTracer
    class QueueWrapper
      def initialize(queue, service_name:)
        @queue = queue
        @service_name = service_name
      end

      def subscribe(**opts, &block)
        @queue.subscribe(**opts) do |delivery_info, properties, payload|
          Datadog::Tracing.trace("rabbitmq.consume", service: @service_name, resource: @queue.name) do |span|
            # Ajouter des tags standards pour RabbitMQ
            span.set_tag("messaging.system", "rabbitmq")
            span.set_tag("messaging.destination", @queue.name)
            span.set_tag("messaging.destination_kind", "queue")

            # Extraire et lier le contexte de trace des headers si présent
            if properties.headers && properties.headers["x-datadog-trace-context"]
              trace_context = JSON.parse(properties.headers["x-datadog-trace-context"])
              span.trace_id = trace_context["trace_id"]
              span.parent_id = trace_context["parent_id"]
            end

            begin
              block.call(delivery_info, properties, payload)
            rescue StandardError => e
              span.set_error(e)
              raise
            end
          end
        end
      end

      def publish(payload, **opts)
        Datadog::Tracing.trace("rabbitmq.publish", service: @service_name, resource: @queue.name) do |span|
          # Ajouter des tags standards
          span.set_tag("messaging.system", "rabbitmq")
          span.set_tag("messaging.destination", @queue.name)
          span.set_tag("messaging.destination_kind", "queue")

          # Injecter le contexte de trace dans les headers
          trace_context = {
            "trace_id" => span.trace_id,
            "parent_id" => span.id
          }

          headers = (opts[:headers] || {}).merge(
            "x-datadog-trace-context" => trace_context.to_json
          )

          begin
            @queue.publish(payload, opts.merge(headers: headers))
          rescue StandardError => e
            span.set_error(e)
            raise
          end
        end
      end
    end
  end
end
