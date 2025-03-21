# frozen_string_literal: true

require "datadog/tracing/contrib"
require "datadog/tracing/contrib/integration"
require "datadog/tracing/contrib/bunny/configuration/settings"
require "datadog/tracing/contrib/bunny/patcher"
require "datadog/tracing/contrib/bunny/utils"

module Datadog
  module Tracing
    module Contrib
      module Bunny
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new("2.0.0")

          register_as :bunny

          def self.gem_name
            "bunny"
          end

          def self.version
            Gem.loaded_specs["bunny"]&.version
          end

          def self.loaded?
            !defined?(::Bunny).nil?
          end

          def self.compatible?
            super && version && version >= MINIMUM_VERSION
          end

          def auto_instrument?
            false
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
