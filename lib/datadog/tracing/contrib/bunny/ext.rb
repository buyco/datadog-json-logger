# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Bunny
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          APP = "bunny"
          ENV_ENABLED = "DD_TRACE_BUNNY_ENABLED"
          ENV_SERVICE_NAME = "DD_TRACE_BUNNY_SERVICE_NAME"
          ENV_ANALYTICS_ENABLED = "DD_TRACE_BUNNY_ANALYTICS_ENABLED"
          ENV_ANALYTICS_SAMPLE_RATE = "DD_TRACE_BUNNY_ANALYTICS_SAMPLE_RATE"
          SPAN_BASIC_PUBLISH = "bunny.publish"
          SPAN_EXCHANGE_NAME = "bunny.exchange"
          SPAN_EXCHANGE_PUBLISH = "bunny.exchange.publish"
          SPAN_CONSUME = "bunny.consume"
          SPAN_QUEUE_NAME = "bunny.queue"
          SPAN_QUEUE_POP = "bunny.queue.pop"
          SPAN_CHANNEL_ID = "bunny.channel.id"
          TAG_MESSAGING_SYSTEM = "rabbitmq"
        end
      end
    end
  end
end
