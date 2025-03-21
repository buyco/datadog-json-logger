# frozen_string_literal: true

require "datadog/tracing/contrib/patcher"
require "datadog/tracing/contrib/bunny/ext"

module Datadog
  module Tracing
    module Contrib
      module Bunny
        # Patcher for Bunny instrumentation
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Bunny::Channel.prepend(ChannelPatch)
            ::Bunny::Exchange.prepend(ExchangePatch)
            ::Bunny::Queue.prepend(QueuePatch)
            ::Bunny::Consumer.prepend(ConsumerPatch)
          end

          # Patch for Bunny::Channel
          module ChannelPatch
            def basic_consume(queue, consumer_tag = generate_consumer_tag, no_ack = false, exclusive = false,
                              arguments = nil, &block)
              config = Datadog.configuration.tracing[:bunny]
              Datadog::Tracing.trace(Ext::SPAN_CONSUME, service: config.service_name) do |span|
                span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::APP)
                span.set_tag(Ext::SPAN_CHANNEL_ID, id)

                super
              end
            end

            def basic_publish(payload, exchange, routing_key, opts = {})
              config = Datadog.configuration.tracing[:bunny]
              Datadog::Tracing.trace(Ext::SPAN_BASIC_PUBLISH, service: config.service_name) do |span|
                span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::APP)
                span.set_tag(Ext::SPAN_CHANNEL_ID, id)

                if (trace_digest = Datadog::Tracing.active_trace&.to_digest)
                  opts[:headers] ||= {}
                  hash = JSON.parse(trace_digest.to_json)
                  opts[:headers].merge!(hash)
                end

                super
              end
            end
          end

          # Patch for Bunny::Exchange
          module ExchangePatch
            def publish(payload, opts = {})
              config = Datadog.configuration.tracing[:bunny]
              Datadog::Tracing.trace(Ext::SPAN_EXCHANGE_PUBLISH, service: config.service_name) do |span|
                span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::APP)
                span.set_tag(Ext::SPAN_EXCHANGE_NAME, name)

                if (trace_digest = Datadog::Tracing.active_trace&.to_digest)
                  opts[:headers] ||= {}
                  hash = JSON.parse(trace_digest.to_json)
                  opts[:headers].merge!(hash)
                end
                super
              end
            end
          end

          # Patch for Bunny::Queue
          module QueuePatch
            def pop(opts = { manual_ack: false }, &block)
              config = Datadog.configuration.tracing[:bunny]
              Datadog::Tracing.trace(Ext::SPAN_QUEUE_POP, service: config.service_name) do |span|
                span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::APP)
                span.set_tag(Ext::SPAN_QUEUE_NAME, name)

                super
              end
            end
          end

          # Patch for Bunny::Consumer
          module ConsumerPatch
            def on_delivery(&block)
              config = Datadog.configuration.tracing[:bunny]
              Datadog::Tracing.trace(Ext::SPAN_CONSUME, service: config.service_name) do |span|
                span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::APP)

                super
              end
            end
          end
        end
      end
    end
  end
end
