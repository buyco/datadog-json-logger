# frozen_string_literal: true

require "spec_helper"
require "datadog/tracing/contrib/bunny/configuration/settings"

RSpec.describe Datadog::Tracing::Contrib::Bunny::Configuration::Settings do
  subject(:settings) { described_class.new }

  it { is_expected.to be_a_kind_of(Datadog::Tracing::Contrib::Configuration::Settings) }

  describe "#service_name" do
    subject(:service_name) { settings.service_name }

    it { is_expected.to eq("bunny") }

    context "when specified" do
      before { settings.service_name = "custom-service" }

      it { is_expected.to eq("custom-service") }
    end
  end

  describe "#analytics_enabled" do
    subject(:analytics_enabled) { settings.analytics_enabled }

    it { is_expected.to be false }

    context "when specified" do
      before { settings.analytics_enabled = true }

      it { is_expected.to be true }
    end
  end

  describe "#analytics_sample_rate" do
    subject(:analytics_sample_rate) { settings.analytics_sample_rate }

    it { is_expected.to eq(1.0) }

    context "when specified" do
      before { settings.analytics_sample_rate = 0.5 }

      it { is_expected.to eq(0.5) }
    end
  end

  describe "#distributed_tracing" do
    subject(:distributed_tracing) { settings.distributed_tracing }

    it { is_expected.to be true }

    context "when specified" do
      before { settings.distributed_tracing = false }

      it { is_expected.to be false }
    end
  end
end
