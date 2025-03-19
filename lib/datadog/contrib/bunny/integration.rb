require 'ddtrace/contrib/integration'
require 'datadog/contrib/bunny/configuration/settings'
require 'datadog/contrib/bunny/patcher'

module Datadog
  module Contrib
    module Bunny
      # Description of Bunny integration
      class Integration
        include Contrib::Integration

        MINIMUM_VERSION = Gem::Version.new('2.0.0')

        register_as :bunny

        def self.version
          Gem.loaded_specs['bunny'] && Gem.loaded_specs['bunny'].version
        end

        def self.loaded?
          !defined?(::Bunny).nil?
        end

        def self.compatible?
          super && version && version >= MINIMUM_VERSION
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