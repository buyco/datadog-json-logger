require 'ddtrace/contrib/patcher'
require 'ddtrace/ext/app_types'
require 'ddtrace/ext/messaging'
require 'datadog/contrib/bunny/ext'

module Datadog
  module Contrib
    module Bunny
      # Patcher for Bunny instrumentation
      module Patcher
        include Contrib::Patcher

        module_function

        def target_version
          Integration.version
        end

        def patch
          ::Bunny::Channel.prepend(ChannelPatch)
          ::Bunny::Exchange.prepend(ExchangePatch)
          ::Bunny::Queue.prepend(QueuePatch)
        end

        # Patch for Bunny::Channel
        module ChannelPatch
          def basic_publish(payload, exchange, routing_key, opts = {})
            datadog_pin = Datadog::Pin.get_from(self)
            return super unless datadog_pin && datadog_pin.enabled?

            config = Datadog.configuration[:bunny]
            
            datadog_pin.tracer.trace(Ext::SPAN_BASIC_PUBLISH, service: datadog_pin.service) do |span|
              span.resource = routing_key
              span.span_type = Datadog::Ext::Messaging::TYPE
              
              # Set tags
              span.set_tag(Datadog::Ext::Messaging::EXCHANGE, exchange)
              span.set_tag(Datadog::Ext::Messaging::ROUTING_KEY, routing_key)
              span.set_tag(Datadog::Ext::Messaging::SYSTEM, Ext::TAG_MESSAGING_SYSTEM)
              
              # Add distributed tracing headers if enabled
              if config[:distributed_tracing]
                inject_datadog_headers!(opts, datadog_pin.tracer)
              end
              
              # Perform the actual publish
              super
            end
          end
          
          def basic_consume(queue, consumer_tag = '', no_ack = false, exclusive = false, arguments = {}, &block)
            datadog_pin = Datadog::Pin.get_from(self)
            
            # If no tracing is set up, call original
            if !datadog_pin || !datadog_pin.enabled?
              return super
            end
            
            # Pass the work to the wrapped consumer
            wrapped_consumer = lambda do |delivery_info, properties, payload|
              config = Datadog.configuration[:bunny]
              
              # Extract distributed tracing context if present
              parent_ctx = nil
              if config[:distributed_tracing] && properties.headers
                parent_ctx = extract_datadog_context(properties.headers)
              end
              
              datadog_pin.tracer.trace(
                Ext::SPAN_CONSUME,
                service: datadog_pin.service,
                child_of: parent_ctx
              ) do |span|
                span.resource = queue
                span.span_type = Datadog::Ext::Messaging::TYPE
                
                # Set tags
                span.set_tag(Datadog::Ext::Messaging::QUEUE, queue)
                span.set_tag(Datadog::Ext::Messaging::EXCHANGE, delivery_info.exchange)
                span.set_tag(Datadog::Ext::Messaging::ROUTING_KEY, delivery_info.routing_key)
                span.set_tag(Datadog::Ext::Messaging::SYSTEM, Ext::TAG_MESSAGING_SYSTEM)
                
                # Call the original block
                block.call(delivery_info, properties, payload)
              end
            end
            
            super(queue, consumer_tag, no_ack, exclusive, arguments, &wrapped_consumer)
          end
          
          private
          
          def inject_datadog_headers!(opts, tracer)
            opts[:headers] ||= {}
            
            tracer.active_correlation.to_h.each do |key, value|
              opts[:headers]["x-datadog-#{key}"] = value.to_s
            end
            
            opts
          end
          
          def extract_datadog_context(headers)
            correlation = {}
            
            headers.each do |key, value|
              if key.to_s.start_with?('x-datadog-')
                correlation[key.to_s.sub('x-datadog-', '')] = value
              end
            end
            
            return nil if correlation.empty?
            
            Datadog::Context.new_from_correlation(correlation)
          end
        end
        
        # Patch for Bunny::Exchange
        module ExchangePatch
          def publish(payload, opts = {})
            datadog_pin = Datadog::Pin.get_from(self)
            return super unless datadog_pin && datadog_pin.enabled?

            config = Datadog.configuration[:bunny]
            
            datadog_pin.tracer.trace(Ext::SPAN_EXCHANGE_PUBLISH, service: datadog_pin.service) do |span|
              span.resource = opts[:routing_key] || ''
              span.span_type = Datadog::Ext::Messaging::TYPE
              
              # Set tags
              span.set_tag(Datadog::Ext::Messaging::EXCHANGE, name)
              span.set_tag(Datadog::Ext::Messaging::EXCHANGE_TYPE, type)
              span.set_tag(Datadog::Ext::Messaging::ROUTING_KEY, opts[:routing_key]) if opts[:routing_key]
              span.set_tag(Datadog::Ext::Messaging::SYSTEM, Ext::TAG_MESSAGING_SYSTEM)
              
              # Add distributed tracing headers if enabled
              if config[:distributed_tracing]
                inject_datadog_headers!(opts, datadog_pin.tracer)
              end
              
              # Perform the actual publish
              super
            end
          end
          
          private
          
          def inject_datadog_headers!(opts, tracer)
            opts[:headers] ||= {}
            
            tracer.active_correlation.to_h.each do |key, value|
              opts[:headers]["x-datadog-#{key}"] = value.to_s
            end
            
            opts
          end
        end
        
        # Patch for Bunny::Queue
        module QueuePatch
          def pop(opts = {})
            datadog_pin = Datadog::Pin.get_from(self)
            return super unless datadog_pin && datadog_pin.enabled?

            config = Datadog.configuration[:bunny]
            
            datadog_pin.tracer.trace(Ext::SPAN_QUEUE_POP, service: datadog_pin.service) do |span|
              span.resource = name
              span.span_type = Datadog::Ext::Messaging::TYPE
              
              # Set tags
              span.set_tag(Datadog::Ext::Messaging::QUEUE, name)
              span.set_tag(Datadog::Ext::Messaging::SYSTEM, Ext::TAG_MESSAGING_SYSTEM)
              
              # Perform the actual pop
              delivery_info, properties, payload = super
              
              if delivery_info
                span.set_tag(Datadog::Ext::Messaging::EXCHANGE, delivery_info.exchange)
                span.set_tag(Datadog::Ext::Messaging::ROUTING_KEY, delivery_info.routing_key)
                
                # Extract distributed tracing context if present
                if config[:distributed_tracing] && properties.headers
                  trace_context = extract_datadog_context(properties.headers)
                  span.context.trace_id = trace_context.trace_id if trace_context
                end
              end
              
              [delivery_info, properties, payload]
            end
          end
          
          private
          
          def extract_datadog_context(headers)
            correlation = {}
            
            headers.each do |key, value|
              if key.to_s.start_with?('x-datadog-')
                correlation[key.to_s.sub('x-datadog-', '')] = value
              end
            end
            
            return nil if correlation.empty?
            
            Datadog::Context.new_from_correlation(correlation)
          end
        end
      end
    end
  end
end