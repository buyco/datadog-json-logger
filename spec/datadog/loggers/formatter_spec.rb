# frozen_string_literal: true

require "spec_helper"
require "datadog/loggers/formatter"

class CustomerFormatter < Datadog::Loggers::Formatter
  def self.call(severity, datetime, progname, msg)
    super do |log_hash|
      log_hash[:my_custom_key] = "my_value"
    end
  end
end

RSpec.describe Datadog::Loggers::Formatter do
  let(:json) { JSON.parse(result) }

  describe "#call" do
    let(:result) { described_class.call("INFO", Time.now, "progname", "Test message") }

    it { expect { json }.not_to raise_error }
    it { expect(json).to include("message", "dd", "progname", "severity", "timestamp") }
    it { expect(json["dd"]).to include("env", "service", "span_id", "trace_id", "version") }
  end

  describe "class ineritance" do
    context "when add custom key to json formatter" do
      let(:result) { CustomerFormatter.call("INFO", Time.now, "progname", "Test message") }

      it { expect(json).to include("my_custom_key") }
    end
  end
end
