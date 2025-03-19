module Datadog
  module Contrib
    module Bunny
      # Bunny integration constants
      module Ext
        APP = 'bunny'.freeze
        ENV_ENABLED = 'DD_TRACE_BUNNY_ENABLED'.freeze
        ENV_SERVICE_NAME = 'DD_TRACE_BUNNY_SERVICE_NAME'.freeze
        ENV_ANALYTICS_ENABLED = 'DD_TRACE_BUNNY_ANALYTICS_ENABLED'.freeze
        ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_BUNNY_ANALYTICS_SAMPLE_RATE'.freeze
        SPAN_BASIC_PUBLISH = 'bunny.publish'.freeze
        SPAN_EXCHANGE_PUBLISH = 'bunny.exchange.publish'.freeze
        SPAN_CONSUME = 'bunny.consume'.freeze
        SPAN_QUEUE_POP = 'bunny.queue.pop'.freeze
        TAG_MESSAGING_SYSTEM = 'rabbitmq'.freeze
      end
    end
  end
end