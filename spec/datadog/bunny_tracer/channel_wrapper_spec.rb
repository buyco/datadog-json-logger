# frozen_string_literal: true

require "spec_helper"
require "bunny"
require "ddtrace"
require "datadog/bunny_tracer"

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
