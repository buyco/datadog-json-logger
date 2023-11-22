# frozen_string_literal: true

require "spec_helper"
require "datadog/json_logger"

RSpec.describe Datadog::JSONLogger do
  let(:output) { StringIO.new }
  subject(:logger) { described_class.new(output) }

  describe "#initialize" do
    it "initializes with default STDOUT" do
      expect(logger.instance_variable_get(:@logdev).dev).to eq(output)
    end
  end

  describe "logging" do
    it "logs messages in JSON format" do
      logger.info("Test message")
      output.rewind
      expect(JSON.parse(output.string)).to include("message" => "Test message")
    end
  end
end
