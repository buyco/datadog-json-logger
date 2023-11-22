# frozen_string_literal: true

require "spec_helper"
require "datadog/loggers/json_formatter"

class CustomFormatter < Datadog::Loggers::JSONFormatter
  def self.call(severity, datetime, progname, msg)
    super do |log_hash|
      log_hash[:my_custom_key] = "my_value"
    end
  end
end

RSpec.describe Datadog::Loggers::JSONFormatter do
  let(:datetime) { Time.now }
  let(:severity) { "INFO" }
  let(:progname) { "progname" }
  let(:json) { JSON.parse(result) }

  describe "#call" do
    context "when message is a string" do
      let(:result) { described_class.call(severity, datetime, progname, "Test message") }

      it { expect { json }.not_to raise_error }
      it { expect(json).to include("message" => "Test message") }

      it { expect(json).to include("dd", "progname", "severity", "timestamp") }
      it { expect(json["dd"]).to include("env", "service", "span_id", "trace_id", "version") }
    end

    context "when message is a hash" do
      let(:message_hash) { { key1: "value1", key2: "value2" } }
      let(:result) { described_class.call(severity, datetime, progname, message_hash) }

      it { expect(json).to include("key1" => "value1", "key2" => "value2") }

      it { expect(json).to include("dd", "progname", "severity", "timestamp") }
      it { expect(json["dd"]).to include("env", "service", "span_id", "trace_id", "version") }
    end

    context "when message is an exception" do
      let(:exception) { StandardError.new("error message") }
      let(:result) { described_class.call(severity, datetime, progname, exception) }

      it { expect(json).to include("exception_message" => "error message") }
      it { expect(json).to include("exception_backtrace") }

      it { expect(json).to include("dd", "progname", "severity", "timestamp") }
      it { expect(json["dd"]).to include("env", "service", "span_id", "trace_id", "version") }
    end

    context "when message is a generic object" do
      let(:object) { Object.new }
      let(:result) { described_class.call(severity, datetime, progname, object) }

      it { expect(json).to include("message" => object.to_s) }

      it { expect(json).to include("dd", "progname", "severity", "timestamp") }
      it { expect(json["dd"]).to include("env", "service", "span_id", "trace_id", "version") }
    end
  end

  describe "class inheritance" do
    context "when adding custom key to json formatter" do
      let(:result) { CustomFormatter.call(severity, datetime, progname, "Test message") }

      it { expect(json).to include("my_custom_key" => "my_value") }

      it { expect(json).to include("dd", "progname", "severity", "timestamp") }
      it { expect(json["dd"]).to include("env", "service", "span_id", "trace_id", "version") }
    end
  end
end
