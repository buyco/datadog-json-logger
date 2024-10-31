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
