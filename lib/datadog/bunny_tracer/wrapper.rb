# frozen_string_literal: true

require "datadog/bunny_tracer/channel_wrapper"

module Datadog
  module BunnyTracer
    class Wrapper
      def initialize(connection, service_name:)
        @connection = connection
        @service_name = service_name
      end

      def create_channel
        channel = @connection.create_channel
        ChannelWrapper.new(channel, service_name: @service_name)
      end
    end
  end
end
