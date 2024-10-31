# frozen_string_literal: true

require "spec_helper"
require "bunny"
require "ddtrace"
require "datadog/bunny_tracer"

RSpec.describe Datadog::BunnyTracer::Wrapper do
  let(:connection) { instance_double(Bunny::Session) }
  let(:channel) { instance_double(Bunny::Channel) }
  let(:service_name) { "test-service" }

  subject { described_class.new(connection, service_name: service_name) }

  before do
    allow(connection).to receive(:create_channel).and_return(channel)
  end

  describe "#create_channel" do
    it "wraps the bunny channel in a ChannelWrapper" do
      wrapped_channel = subject.create_channel
      expect(wrapped_channel).to be_a(Datadog::BunnyTracer::ChannelWrapper)
    end
  end
end

RSpec.describe Datadog::BunnyTracer::ChannelWrapper do
  let(:channel) { instance_double(Bunny::Channel) }
  let(:queue) { instance_double(Bunny::Queue) }
  let(:exchange) { instance_double(Bunny::Exchange) }
  let(:service_name) { "test-service" }

  subject { described_class.new(channel, service_name: service_name) }

  before do
    allow(channel).to receive(:queue).and_return(queue)
    allow(channel).to receive(:exchange).and_return(exchange)
  end

  describe "#queue" do
    it "wraps the bunny queue in a QueueWrapper" do
      wrapped_queue = subject.queue("test-queue")
      expect(wrapped_queue).to be_a(Datadog::BunnyTracer::QueueWrapper)
    end

    it "passes options to the underlying queue" do
      opts = { durable: true, auto_delete: false }
      subject.queue("test-queue", **opts)
      expect(channel).to have_received(:queue).with("test-queue", opts)
    end
  end

  describe "#exchange" do
    it "wraps the bunny exchange in an ExchangeWrapper" do
      wrapped_exchange = subject.exchange("test-exchange")
      expect(wrapped_exchange).to be_a(Datadog::BunnyTracer::ExchangeWrapper)
    end

    it "passes type and options to the underlying exchange" do
      opts = { durable: true }
      subject.exchange("test-exchange", type: :topic, **opts)
      expect(channel).to have_received(:exchange).with("test-exchange", type: :topic, **opts)
    end
  end
end

RSpec.describe Datadog::BunnyTracer::QueueWrapper do
  let(:queue) { instance_double(Bunny::Queue, name: "test-queue") }
  let(:service_name) { "test-service" }
  let(:delivery_info) { instance_double(Bunny::DeliveryInfo) }
  let(:properties) { instance_double(Bunny::MessageProperties) }
  let(:payload) { { data: "test" }.to_json }

  subject { described_class.new(queue, service_name: service_name) }

  describe "#subscribe" do
    before do
      allow(properties).to receive(:headers).and_return({})
      allow(queue).to receive(:subscribe).and_yield(delivery_info, properties, payload)
    end

    it "creates a span with correct tags" do
      subject.subscribe do |_di, _props, _msg|
        span = Datadog::Tracing.active_span
        expect(span.service).to eq(service_name)
        expect(span.resource).to eq("test-queue")
        expect(span.get_tag("messaging.system")).to eq("rabbitmq")
        expect(span.get_tag("messaging.destination")).to eq("test-queue")
        expect(span.get_tag("messaging.destination_kind")).to eq("queue")
      end
    end

    context "with trace context in headers" do
      let(:trace_context) { { "trace_id" => "123", "parent_id" => "456" } }

      before do
        allow(properties).to receive(:headers).and_return({
                                                            "x-datadog-trace-context" => trace_context.to_json
                                                          })
      end

      it "preserves trace context" do
        subject.subscribe do |_di, _props, _msg|
          span = Datadog::Tracing.active_span
          expect(span.trace_id).to eq(trace_context["trace_id"])
          expect(span.parent_id).to eq(trace_context["parent_id"])
        end
      end
    end

    it "handles errors during processing" do
      error = StandardError.new("Processing failed")

      expect do
        subject.subscribe do |_di, _props, _msg|
          raise error
        end
      end.to raise_error(StandardError)

      span = Datadog::Tracing.active_span
      expect(span.status).to eq(1)
      expect(span.get_tag("error.type")).to eq("StandardError")
      expect(span.get_tag("error.message")).to eq("Processing failed")
    end
  end

  describe "#publish" do
    before do
      allow(queue).to receive(:publish)
    end

    it "creates a span with correct tags" do
      subject.publish(payload)

      span = Datadog::Tracing.active_span
      expect(span.service).to eq(service_name)
      expect(span.resource).to eq("test-queue")
      expect(span.get_tag("messaging.system")).to eq("rabbitmq")
      expect(span.get_tag("messaging.destination")).to eq("test-queue")
      expect(span.get_tag("messaging.destination_kind")).to eq("queue")
    end

    it "injects trace context into headers" do
      subject.publish(payload)

      expect(queue).to have_received(:publish).with(
        payload,
        hash_including(
          headers: include(
            "x-datadog-trace-context" => match(/"trace_id":.+,"parent_id":.+/)
          )
        )
      )
    end

    it "preserves existing headers" do
      existing_headers = { "custom-header" => "value" }
      subject.publish(payload, headers: existing_headers)

      expect(queue).to have_received(:publish).with(
        payload,
        hash_including(
          headers: include(
            "custom-header" => "value",
            "x-datadog-trace-context" => be_a(String)
          )
        )
      )
    end

    it "handles errors during publish" do
      error = StandardError.new("Publish failed")
      allow(queue).to receive(:publish).and_raise(error)

      expect do
        subject.publish(payload)
      end.to raise_error(StandardError)

      span = Datadog::Tracing.active_span
      expect(span.status).to eq(1)
      expect(span.get_tag("error.type")).to eq("StandardError")
      expect(span.get_tag("error.message")).to eq("Publish failed")
    end
  end
end

RSpec.describe Datadog::BunnyTracer::ExchangeWrapper do
  let(:exchange) { instance_double(Bunny::Exchange, name: "test-exchange") }
  let(:service_name) { "test-service" }
  let(:payload) { { data: "test" }.to_json }
  let(:routing_key) { "test.route" }

  subject { described_class.new(exchange, service_name: service_name) }

  describe "#publish" do
    before do
      allow(exchange).to receive(:publish)
    end

    it "creates a span with correct tags" do
      subject.publish(payload, routing_key: routing_key)

      span = Datadog::Tracing.active_span
      expect(span.service).to eq(service_name)
      expect(span.resource).to eq("test-exchange")
      expect(span.get_tag("messaging.system")).to eq("rabbitmq")
      expect(span.get_tag("messaging.destination")).to eq("test-exchange")
      expect(span.get_tag("messaging.destination_kind")).to eq("exchange")
      expect(span.get_tag("messaging.routing_key")).to eq(routing_key)
    end

    it "injects trace context into headers" do
      subject.publish(payload, routing_key: routing_key)

      expect(exchange).to have_received(:publish).with(
        payload,
        hash_including(
          routing_key: routing_key,
          headers: include(
            "x-datadog-trace-context" => match(/"trace_id":.+,"parent_id":.+/)
          )
        )
      )
    end

    it "preserves existing headers and options" do
      existing_headers = { "custom-header" => "value" }
      additional_opts = { persistent: true }

      subject.publish(
        payload,
        routing_key: routing_key,
        headers: existing_headers,
        **additional_opts
      )

      expect(exchange).to have_received(:publish).with(
        payload,
        hash_including(
          routing_key: routing_key,
          persistent: true,
          headers: include(
            "custom-header" => "value",
            "x-datadog-trace-context" => be_a(String)
          )
        )
      )
    end

    it "handles errors during publish" do
      error = StandardError.new("Publish failed")
      allow(exchange).to receive(:publish).and_raise(error)

      expect do
        subject.publish(payload, routing_key: routing_key)
      end.to raise_error(StandardError)

      span = Datadog::Tracing.active_span
      expect(span.status).to eq(1)
      expect(span.get_tag("error.type")).to eq("StandardError")
      expect(span.get_tag("error.message")).to eq("Publish failed")
    end
  end
end
