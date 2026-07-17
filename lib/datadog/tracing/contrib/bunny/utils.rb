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
                                        metadata.transform_keys(&:to_sym)
                                      elsif metadata.is_a?(String)
                                        JSON.parse(metadata, symbolize_names: true)
                                      else
                                        return
                                      end

            # A producer on a newer datadog gem may serialize digest fields this
            # consumer's TraceDigest does not know yet; drop them instead of raising.
            serializes_trace_digest = serializes_trace_digest.slice(*supported_trace_digest_keys)

            trace_digest = Datadog::Tracing::TraceDigest.new(**serializes_trace_digest)
            return unless trace_digest

            Datadog::Tracing.continue_trace!(trace_digest)
          end

          # @return [Array<Symbol>]
          def supported_trace_digest_keys
            @supported_trace_digest_keys ||=
              Datadog::Tracing::TraceDigest.instance_method(:initialize).parameters.filter_map do |type, name|
                name if %i[key keyreq].include?(type)
              end
          end
        end
      end
    end
  end
end

# Datadog::Tracing::Contrib::Bunny::Utils.continue_trace!(metadata)
