# frozen_string_literal: true

require "spec_helper"
require "bunny"
require "datadog/tracing/contrib/bunny/patcher"

RSpec.describe Datadog::Tracing::Contrib::Bunny::Patcher do
  let(:patcher) { described_class }

  describe "::patch" do
    subject(:patch) { patcher.patch }

    before do
      allow(patcher).to receive(:patch).and_return(true)
    end

    it "patches Bunny classes with instrumentation" do
      expect(Bunny::Channel).to receive(:prepend).with(Datadog::Tracing::Contrib::Bunny::Patcher::ChannelPatch)
      expect(Bunny::Exchange).to receive(:prepend).with(Datadog::Tracing::Contrib::Bunny::Patcher::ExchangePatch)
      expect(Bunny::Queue).to receive(:prepend).with(Datadog::Tracing::Contrib::Bunny::Patcher::QueuePatch)

      Bunny::Channel.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ChannelPatch)
      Bunny::Exchange.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ExchangePatch)
      Bunny::Queue.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::QueuePatch)
    end
  end

  describe "ChannelPatch" do
    let(:channel_class) do
      Class.new do
        def id
          1
        end

        def generate_consumer_tag
          "tag"
        end

        def basic_consume(*_args); end

        def basic_publish(*_args); end
      end
    end
    let(:patched_channel_class) do
      klass = channel_class
      klass.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ChannelPatch)
      klass
    end
    let(:channel) { patched_channel_class.new }
    let(:config) { double("config", service_name: "test-service") }

    before do
      allow(Datadog).to receive_message_chain(:configuration, :tracing).and_return({ bunny: config })
    end

    describe "#basic_consume" do
      it "traces the consume operation" do
        expect(Datadog::Tracing).to receive(:trace).with("bunny.consume", service: "test-service")
        channel.basic_consume("queue")
      end
    end

    describe "#basic_publish" do
      it "traces the publish operation" do
        expect(Datadog::Tracing).to receive(:trace).with("bunny.publish", service: "test-service")
        channel.basic_publish("payload", "exchange", "routing_key")
      end
    end
  end

  describe "ExchangePatch" do
    let(:exchange_class) do
      Class.new do
        def name
          "exchange-name"
        end

        def publish(*_args); end
      end
    end
    let(:patched_exchange_class) do
      klass = exchange_class
      klass.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ExchangePatch)
      klass
    end
    let(:exchange) { patched_exchange_class.new }
    let(:config) { double("config", service_name: "test-service") }

    before do
      allow(Datadog).to receive_message_chain(:configuration, :tracing).and_return({ bunny: config })
    end

    describe "#publish" do
      it "traces the exchange publish operation" do
        expect(Datadog::Tracing).to receive(:trace).with("bunny.exchange.publish", service: "test-service")
        exchange.publish("payload")
      end
    end
  end

  describe "QueuePatch" do
    let(:queue_class) do
      Class.new do
        def name
          "queue-name"
        end

        def pop(*_args); end
      end
    end
    let(:patched_queue_class) do
      klass = queue_class
      klass.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::QueuePatch)
      klass
    end
    let(:queue) { patched_queue_class.new }
    let(:config) { double("config", service_name: "test-service") }

    before do
      allow(Datadog).to receive_message_chain(:configuration, :tracing).and_return({ bunny: config })
    end

    describe "#pop" do
      it "traces the queue pop operation" do
        expect(Datadog::Tracing).to receive(:trace).with("bunny.queue.pop", service: "test-service")
        queue.pop
      end
    end
  end
end
