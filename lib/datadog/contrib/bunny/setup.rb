require 'ddtrace/contrib/setup'
require 'datadog/contrib/bunny/integration'

module Datadog
  module Contrib
    module Bunny
      # Implements patch operations for Bunny
      class Setup < Contrib::Setup
        def auto_instrument
          Datadog.configuration[:bunny].distributed_tracing = true
        end

        def patch
          ::Bunny.module_eval do
            def self.new(*args, &block)
              instance = super
              
              datadog_pin = Datadog::Pin.new(
                Datadog.configuration[:bunny][:service_name],
                app: Datadog::Contrib::Bunny::Ext::APP,
                app_type: Datadog::Ext::AppTypes::MESSAGE_PRODUCER,
                tracer: Datadog.tracer
              )
              
              datadog_pin.onto(instance)
              
              instance
            end
          end
          
          super
        end
      end
    end
  end
end