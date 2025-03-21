# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Bunny
        module Utils
          module_function

          # @param metadata [Hash, String]
          # @return [void]
          def continue_trace!(metadata)
            serializes_trace_digest = if metadata.is_a?(Hash)
              metadata.deep_symbolize_keys
            elsif metadata.is_a?(String)
              JSON.parse(metadata, symbolize_names: true)
            else
              return
            end

            trace_digest = Datadog::Tracing::TraceDigest.new(**serializes_trace_digest)
            return unless trace_digest

            Datadog::Tracing.continue_trace!(trace_digest)
          end
        end
      end
    end
  end
end

# Datadog::Tracing::Contrib::Bunny::Utils.continue_trace!(metadata)