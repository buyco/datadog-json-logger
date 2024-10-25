# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "datadog/json_logger"
require "datadog/sinatra_middleware"

RSpec.describe Datadog::SinatraMiddleware do
  let(:app) { ->(_env) { [status_code, { "Content-Type" => "text/html" }, ["Response"]] } }
  let(:env) { Rack::MockRequest.env_for("/test") }
  let(:logger) { Datadog::JSONLogger.new }
  let(:middleware) { described_class.new(app, logger) }
  let(:status_code) { 200 }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:config).and_return(Datadog::Configuration.new)
  end

  describe "#call" do
    context "when making a GET request" do
      let(:env) { Rack::MockRequest.env_for("/test?foo=bar", method: "GET") }
      let(:message) do
        "Received GET request from  at /test Responded with status 200 in 0ms."
      end

      it "logs GET requests" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_including(method: "GET"))
        expect(logger).to have_received(:info).with(hash_including(message: message))
      end
    end

    context "when making a POST request" do
      let(:env) { Rack::MockRequest.env_for("/test", method: "POST", params: { foo: "bar" }) }
      let(:message) do
        "Received POST request from  at /test Responded with status 200 in 0ms."
      end

      it "logs POST requests with parameters" do
        middleware.call(env)
        expect(logger).to have_received(:info)
          .with(hash_including(method: "POST"))
          .with(hash_not_including(params: { "foo" => "bar" }))
        expect(logger).to have_received(:info).with(hash_including(message: message))
      end
    end

    context "when the response is an error" do
      let(:status_code) { 500 }
      let(:env) { Rack::MockRequest.env_for("/error") }

      it "logs the error status code" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_including(status: 500))
      end
    end

    context "when request contains custom headers" do
      let(:env) { Rack::MockRequest.env_for("/test", { "HTTP_CUSTOM_HEADER" => "CustomValue" }) }

      it "logs requests with custom headers" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_not_including(headers: include("Custom-Header")))
      end
    end

    context "when response content type is JSON" do
      let(:app) { ->(_env) { [200, { "Content-Type" => "application/json" }, ['{"message":"OK"}']] } }

      it "logs JSON content type responses" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_including(format: "application/json"))
      end
    end

    context "when request has multiple query parameters" do
      let(:env) { Rack::MockRequest.env_for("/test?foo=bar&baz=qux") }

      it "logs multiple query parameters" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_including(params: include("foo", "baz")))
      end
    end

    context "when response is a redirect" do
      let(:status_code) { 302 }
      let(:env) { Rack::MockRequest.env_for("/redirect") }

      it "logs redirect status code" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_including(status: 302))
      end
    end

    context "when raise_exceptions is set to true" do
      let(:middleware) { described_class.new(app, logger, raise_exceptions: true) }
      let(:app) { ->(_env) { raise StandardError, "Something went wrong" } }

      it "re-raises exceptions" do
        expect { middleware.call(Rack::MockRequest.env_for("/test", method: "GET")) }
          .to raise_error(StandardError, "Something went wrong")
      end
    end

    context "when raise_exceptions is set to false" do
      let(:middleware) { described_class.new(app, logger, raise_exceptions: false) }
      let(:app) { ->(_env) { raise StandardError, "Something went wrong" } }

      it "handles exceptions without re-raising" do
        expect { middleware.call(Rack::MockRequest.env_for("/test", method: "GET")) }
          .not_to raise_error
      end
    end

    context "when current_user is set" do
      before do
        allow(logger.config).to receive(:current_user).and_return(current_user)
        allow(logger.config).to receive(:log_current_user?).and_return(true)
      end

      context "when current_user is fixed" do
        let(:current_user) do
          ->(_env) { { id: 1, email: "john-doe@gmail.com" } }
        end

        it "logs the current user" do
          middleware.call(env)
          expect(logger).to have_received(:info).with(hash_including(user: current_user))
        end
      end

      context "when current_user is in env" do
        let(:user) { { id: 1, email: "john-doe@gmail.com" } }
        let(:current_user) do
          ->(env) { env["current_user"] }
        end

        before { env["current_user"] = user }

        it "logs the current user" do
          middleware.call(env)
          expect(logger).to have_received(:info).with(hash_including(user: user))
        end
      end

      context "when current_user is warned" do
        let(:user) { double("User", id: 1, email: "john-doe@gmail.com") }
        let(:current_user) do
          ->(env) { { id: env["user"].user.id, email: env["user"].user.email } }
        end

        before { env["user"] = double("User", user: user) }

        it "does not log the current user" do
          middleware.call(env)
          expect(logger).to have_received(:info).with(including(:user))
        end
      end
    end

    context "when current_user is not set" do
      before do
        allow(logger.config).to receive(:current_user).and_return(nil)
        allow(logger.config).to receive(:log_current_user?).and_return(false)
      end

      it "does not log the current user" do
        middleware.call(env)
        expect(logger).to have_received(:info).with(hash_not_including(:user))
      end
    end
  end
end
