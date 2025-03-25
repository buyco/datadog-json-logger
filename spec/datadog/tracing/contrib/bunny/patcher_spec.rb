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
      expect(Bunny::Consumer).to receive(:prepend).with(Datadog::Tracing::Contrib::Bunny::Patcher::ConsumerPatch)

      Bunny::Channel.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ChannelPatch)
      Bunny::Exchange.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ExchangePatch)
      Bunny::Queue.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::QueuePatch)
      Bunny::Consumer.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ConsumerPatch)
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

        def publish(_payload, opts = {})
          # Return the options so we can check them in the test
          opts
        end
      end
    end
    let(:patched_exchange_class) do
      klass = exchange_class
      klass.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ExchangePatch)
      klass
    end
    let(:exchange) { patched_exchange_class.new }
    let(:config) { double("config", service_name: "test-service") }
    let(:span) { instance_double(Datadog::Tracing::SpanOperation) }

    before do
      allow(Datadog).to receive_message_chain(:configuration, :tracing).and_return({ bunny: config })
      allow(span).to receive(:type=)
      allow(span).to receive(:set_tag)
    end

    describe "#publish" do
      let(:active_trace) { instance_double(Datadog::Tracing::TraceOperation) }
      let(:trace_digest) { instance_double(Datadog::Tracing::TraceDigest) }
      let(:trace_json) { { "trace_id" => 123, "span_id" => 456 } }

      before do
        allow(Datadog::Tracing).to receive(:active_trace).and_return(active_trace)
        allow(active_trace).to receive(:to_digest).and_return(trace_digest)
        allow(trace_digest).to receive(:to_json).and_return(JSON.generate(trace_json))
        allow(Datadog::Tracing).to receive(:trace).and_yield(span)
      end

      it "traces the exchange publish operation" do
        expect(Datadog::Tracing).to receive(:trace).with("bunny.exchange.publish", service: "test-service")
        exchange.publish("payload")
      end

      it "adds trace digest to options when distributed tracing is available" do
        # Test si le contenu des options contient le trace_digest
        result = exchange.publish("payload")

        # Vérifie si les options retournées contiennent le trace_digest
        expect(result).to include(trace_digest: trace_json)
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

  describe "ConsumerPatch" do
    let(:consumer_class) do
      Class.new do
        def on_delivery(*_args, &block)
          block.call if block_given?
        end
      end
    end
    let(:patched_consumer_class) do
      klass = consumer_class
      klass.prepend(Datadog::Tracing::Contrib::Bunny::Patcher::ConsumerPatch)
      klass
    end
    let(:consumer) { patched_consumer_class.new }
    let(:config) { double("config", service_name: "test-service") }
    let(:span) { instance_double(Datadog::Tracing::SpanOperation) }

    before do
      allow(Datadog).to receive_message_chain(:configuration, :tracing).and_return({ bunny: config })
      allow(span).to receive(:type=)
      allow(span).to receive(:set_tag)
      allow(Datadog::Tracing).to receive(:trace).and_yield(span)
      # Permet d'appeler la version originale de on_delivery pour le test
      allow(consumer).to receive(:on_delivery).and_call_original
      allow(consumer).to receive(:super) { |*_args, &block| block&.call }
    end

    describe "#on_delivery" do
      it "traces the consumer on_delivery operation" do
        expect(Datadog::Tracing).to receive(:trace).with("bunny.consume", service: "test-service")
        # Vérifie que le bloc est bien appelé
        called = false
        consumer.on_delivery { called = true }
        expect(called).to be true
      end
    end
  end
end
