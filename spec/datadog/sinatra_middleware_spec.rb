# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "datadog/sinatra_middleware"

RSpec.describe Datadog::SinatraMiddleware do
  let(:app) { ->(_env) { [200, { "Content-Type" => "text/html" }, ["OK"]] } }
  let(:logger) { instance_double("Logger") }
  let(:middleware) { described_class.new(app, logger) }
  let(:env) { Rack::MockRequest.env_for("/test?foo=bar") }

  before do
    allow(logger).to receive(:info)
  end

  describe "#call" do
    it "logs the request" do
      middleware.call(env)
      expect(logger).to have_received(:info).with(hash_including(:request, :request_ip, :method))
    end
  end
end
