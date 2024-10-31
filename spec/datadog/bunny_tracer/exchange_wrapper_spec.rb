# frozen_string_literal: true

require "spec_helper"
require "bunny"
require "ddtrace"
require "datadog/bunny_tracer"

RSpec.describe Datadog::BunnyTracer::ExchangeWrapper do
  let(:exchange) { instance_double(Bunny::Exchange, name: "test-exchange") }
  let(:dd_trace) { instance_double(Datadog::Tracing::TraceOperation) }
  let(:span) { instance_double(Datadog::Tracing::SpanOperation) }
  let(:service_name) { "test-service" }
  let(:payload) { { data: "test" }.to_json }
  let(:routing_key) { "test.route" }

  subject { described_class.new(exchange, service_name: service_name) }

  before do
    allow(Datadog::Tracing).to receive(:trace).and_yield(span)
    allow(span).to receive(:service).and_return(service_name)
    allow(span).to receive(:resource).and_return("test-exchange")

    allow(span).to receive(:set_tag)
    allow(span).to receive(:get_tag)
    allow(span).to receive(:trace_id).and_return(123)
    allow(span).to receive(:id).and_return(456)
    allow(span).to receive(:parent_id)
    allow(span).to receive(:status=)
    allow(span).to receive(:set_error)
    allow(exchange).to receive(:publish)
  end

  describe "#publish" do
    before do
      allow(exchange).to receive(:publish)
    end

    it "creates a span with correct tags" do
      subject.publish(payload, routing_key: routing_key)

      expect(span).to have_received(:set_tag).with("messaging.system", "rabbitmq")
      expect(span).to have_received(:set_tag).with("messaging.destination", "test-exchange")
      expect(span).to have_received(:set_tag).with("messaging.destination_kind", "exchange")
      expect(span).to have_received(:set_tag).with("messaging.routing_key", routing_key)
    end

    it "injects trace context into headers" do
      subject.publish(payload, routing_key: routing_key)

      expect(exchange).to have_received(:publish).with(
        payload,
        hash_including(
          routing_key: routing_key,
          headers: include(
            "x-datadog-trace-context" => match(/"trace_id":.+,"span_id":.+/)
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

      expect(span).to have_received(:set_error).with(error)
    end
  end
end
