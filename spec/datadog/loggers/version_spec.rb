# frozen_string_literal: true

require "spec_helper"
require "datadog/loggers/version"

RSpec.describe Datadog::Loggers::VERSION do
  it "has a version number" do
    expect(Datadog::Loggers::VERSION).not_to be nil
  end
end
