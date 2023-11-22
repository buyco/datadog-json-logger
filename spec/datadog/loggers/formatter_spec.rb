# frozen_string_literal: true

require "spec_helper"
require "datadog/loggers/formatter"

RSpec.describe Datadog::Loggers::Formatter do
  describe ".call" do
    it "formats messages as JSON" do
      result = described_class.call("INFO", Time.now, "progname", "Test message")
      expect { JSON.parse(result) }.not_to raise_error
    end
  end
end
