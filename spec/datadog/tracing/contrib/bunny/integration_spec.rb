# frozen_string_literal: true

require "spec_helper"
require "bunny"
require "datadog/tracing/contrib/bunny/integration"

RSpec.describe Datadog::Tracing::Contrib::Bunny::Integration do
  let(:registry) { double("registry") }
  let(:integration) { described_class.new(registry) }

  describe "::gem_name" do
    subject { described_class.gem_name }

    it { is_expected.to eq("bunny") }
  end

  describe "::version" do
    subject { described_class.version }

    context "when bunny is installed" do
      it { is_expected.to be_a_kind_of(Gem::Version) }
    end
  end

  describe "::loaded?" do
    subject { described_class.loaded? }

    context "when bunny is defined" do
      it { is_expected.to be true }
    end
  end

  describe "::compatible?" do
    subject { described_class.compatible? }

    context "when bunny is compatible" do
      it { is_expected.to be true }
    end

    context "when bunny is not compatible" do
      before do
        allow(described_class).to receive(:version).and_return(Gem::Version.new("1.0.0"))
      end

      it { is_expected.to be false }
    end
  end

  describe "#auto_instrument?" do
    subject { integration.auto_instrument? }

    it { is_expected.to be false }
  end

  describe "#new_configuration" do
    subject { integration.new_configuration }

    it { is_expected.to be_a_kind_of(Datadog::Tracing::Contrib::Bunny::Configuration::Settings) }
  end

  describe "#patcher" do
    subject { integration.patcher }

    it { is_expected.to be Datadog::Tracing::Contrib::Bunny::Patcher }
  end
end
