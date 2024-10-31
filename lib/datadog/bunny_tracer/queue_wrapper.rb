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
            span.set_tag("messaging.system", "rabbitmq")
            span.set_tag("messaging.destination", @queue.name)
            span.set_tag("messaging.destination_kind", "queue")

            if properties.headers && properties.headers["x-datadog-trace-context"]
              trace_context = JSON.parse(properties.headers["x-datadog-trace-context"], symbolize_names: true)
              trace_digest = Datadog::Tracing::TraceDigest.new(**trace_context)
              Datadog::Tracing.continue_trace!(trace_digest) if trace_digest
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
          span.set_tag("messaging.system", "rabbitmq")
          span.set_tag("messaging.destination", @queue.name)
          span.set_tag("messaging.destination_kind", "queue")

          trace_context = {
            trace_id: span.trace_id,
            span_id: span.id,
            parent_id: span.parent_id
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
