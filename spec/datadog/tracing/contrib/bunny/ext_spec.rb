# frozen_string_literal: true

require "spec_helper"
require "datadog/tracing/contrib/bunny/ext"

RSpec.describe Datadog::Tracing::Contrib::Bunny::Ext do
  describe "constants" do
    it "has the correct app name" do
      expect(described_class::APP).to eq("bunny")
    end

    it "has the correct environment variable prefixes" do
      expect(described_class::ENV_ENABLED).to eq("DD_TRACE_BUNNY_ENABLED")
      expect(described_class::ENV_SERVICE_NAME).to eq("DD_TRACE_BUNNY_SERVICE_NAME")
      expect(described_class::ENV_ANALYTICS_ENABLED).to eq("DD_TRACE_BUNNY_ANALYTICS_ENABLED")
      expect(described_class::ENV_ANALYTICS_SAMPLE_RATE).to eq("DD_TRACE_BUNNY_ANALYTICS_SAMPLE_RATE")
    end

    it "has the correct span names" do
      expect(described_class::SPAN_BASIC_PUBLISH).to eq("bunny.publish")
      expect(described_class::SPAN_EXCHANGE_PUBLISH).to eq("bunny.exchange.publish")
      expect(described_class::SPAN_CONSUME).to eq("bunny.consume")
      expect(described_class::SPAN_QUEUE_POP).to eq("bunny.queue.pop")
    end

    it "has the correct messaging system" do
      expect(described_class::TAG_MESSAGING_SYSTEM).to eq("rabbitmq")
    end
  end
end
