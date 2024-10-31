# frozen_string_literal: true

require "spec_helper"
require "bunny"
require "ddtrace"
require "datadog/bunny_tracer"

RSpec.describe Datadog::BunnyTracer::QueueWrapper do
  let(:queue) { instance_double(Bunny::Queue, name: "test-queue") }
  let(:service_name) { "test-service" }
  let(:delivery_info) { instance_double(Bunny::DeliveryInfo) }
  let(:properties) { instance_double(Bunny::MessageProperties) }
  let(:payload) { { data: "test" }.to_json }
  let(:dd_trace) { instance_double(Datadog::Tracing::TraceOperation) }
  let(:span) { instance_double(Datadog::Tracing::SpanOperation) }

  subject { described_class.new(queue, service_name: service_name) }

  before do
    allow(Datadog::Tracing).to receive(:trace).and_yield(span)
    allow(span).to receive(:service).and_return(service_name)
    allow(span).to receive(:resource).and_return("test-queue")

    allow(span).to receive(:set_tag)
    allow(span).to receive(:get_tag)
    allow(span).to receive(:trace_id).and_return(123)
    allow(span).to receive(:id).and_return(456)
    allow(span).to receive(:parent_id)
    allow(span).to receive(:status=)
    allow(span).to receive(:set_error)
    allow(queue).to receive(:publish)
  end

  describe "#subscribe" do
    before do
      allow(properties).to receive(:headers).and_return({})
      allow(queue).to receive(:subscribe).and_yield(delivery_info, properties, payload)
    end

    it "creates a span with correct tags" do
      subject.subscribe do |_di, _props, _msg|
        # subscription block
      end

      expect(span).to have_received(:set_tag).with("messaging.system", "rabbitmq")
      expect(span).to have_received(:set_tag).with("messaging.destination", "test-queue")
      expect(span).to have_received(:set_tag).with("messaging.destination_kind", "queue")
    end

    context "with trace context in headers" do
      let(:trace_context) { { "trace_id" => "123", "span_id" => "456" } }

      before do
        allow(properties).to receive(:headers).and_return({
                                                            "x-datadog-trace-context" => trace_context.to_json
                                                          })
      end

      it "preserves trace context" do
        subject.subscribe do |_di, _props, _msg|
          dd_trace = Datadog::Tracing.active_trace
          expect(dd_trace.id).to eq(trace_context["trace_id"])
          expect(dd_trace.parent_span_id).to eq(trace_context["span_id"])
        end
      end
    end
  end

  describe "#publish" do
    before do
      allow(queue).to receive(:publish)
    end

    it "creates a span with correct tags" do
      subject.publish(payload)

      expect(span).to have_received(:set_tag).with("messaging.system", "rabbitmq")
      expect(span).to have_received(:set_tag).with("messaging.destination", "test-queue")
      expect(span).to have_received(:set_tag).with("messaging.destination_kind", "queue")
    end

    it "injects trace context into headers" do
      subject.publish(payload)

      expect(queue).to have_received(:publish).with(
        payload,
        hash_including(
          headers: include(
            "x-datadog-trace-context" => match(/"trace_id":.+,"span_id":.+/)
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

      expect(span).to have_received(:set_error).with(error)
    end
  end
end
