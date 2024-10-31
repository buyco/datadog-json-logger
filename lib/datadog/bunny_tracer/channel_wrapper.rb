# frozen_string_literal: true

require "datadog/bunny_tracer/queue_wrapper"
require "datadog/bunny_tracer/exchange_wrapper"

module Datadog
  module BunnyTracer
    class ChannelWrapper
      def initialize(channel, service_name:)
        @channel = channel
        @service_name = service_name
      end

      def queue(name, **opts)
        queue = @channel.queue(name, **opts)
        QueueWrapper.new(queue, service_name: @service_name)
      end

      def exchange(name, type: :direct, **opts)
        exchange = @channel.exchange(name, type: type, **opts)
        ExchangeWrapper.new(exchange, service_name: @service_name)
      end
    end
  end
end
