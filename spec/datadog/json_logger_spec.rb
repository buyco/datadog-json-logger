# frozen_string_literal: true

require "spec_helper"
require "datadog/json_logger"

RSpec.describe Datadog::JSONLogger do
  let(:output) { StringIO.new }
  subject(:logger) { described_class.new(output) }

  describe "#initialize" do
    it "initializes with custom output" do
      expect(logger.instance_variable_get(:@logdev).dev).to eq(output)
    end
  end

  describe "logging" do
    let(:log) do
      output.rewind
      JSON.parse(output.string)
    end

    before { logger.info("Test message") }

    it { expect(log).to include("message" => "Test message") }
  end
end
