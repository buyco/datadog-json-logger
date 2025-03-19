# frozen_string_literal: true

require "datadog/tracing/contrib/configuration/settings"

module Datadog
  module Tracing
    module Contrib
      module Bunny
        module Configuration
          # Configuration settings for Bunny
          class Settings < Contrib::Configuration::Settings
            option :service_name, default: "bunny"
            option :analytics_enabled, default: false
            option :analytics_sample_rate, default: 1.0
            option :distributed_tracing, default: true
          end
        end
      end
    end
  end
end
