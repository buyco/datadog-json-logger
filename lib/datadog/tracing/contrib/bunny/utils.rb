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
                                        # Convertit les clés en symboles de manière récursive
                                        symbolize_keys(metadata)
                                      elsif metadata.is_a?(String)
                                        JSON.parse(metadata, symbolize_names: true)
                                      else
                                        return
                                      end

            trace_digest = Datadog::Tracing::TraceDigest.new(**serializes_trace_digest)
            return unless trace_digest

            Datadog::Tracing.continue_trace!(trace_digest)
          end

          # Méthode pour convertir récursivement les clés d'un hash en symboles
          # @param hash [Hash] Le hash à convertir
          # @return [Hash] Le hash avec des clés symboliques
          def symbolize_keys(hash)
            hash.each_with_object({}) do |(key, value), result|
              new_key = key.is_a?(String) ? key.to_sym : key
              new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
              result[new_key] = new_value
            end
          end
        end
      end
    end
  end
end

# Datadog::Tracing::Contrib::Bunny::Utils.continue_trace!(metadata)
