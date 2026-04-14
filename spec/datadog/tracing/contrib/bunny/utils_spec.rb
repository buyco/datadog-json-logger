# frozen_string_literal: true

require "spec_helper"
require "json"
require "datadog/tracing/contrib/bunny/utils"

RSpec.describe Datadog::Tracing::Contrib::Bunny::Utils do
  describe "::continue_trace!" do
    let(:trace_digest) { instance_double(Datadog::Tracing::TraceDigest) }
    let(:metadata) { { trace_id: 123, span_id: 456 } }

    before do
      allow(Datadog::Tracing::TraceDigest).to receive(:new).and_return(trace_digest)
      allow(Datadog::Tracing).to receive(:continue_trace!)
    end

    context "when metadata is a hash" do
      it "continues the trace with the trace digest" do
        described_class.continue_trace!(metadata)

        expect(Datadog::Tracing::TraceDigest).to have_received(:new).with(trace_id: 123, span_id: 456)
        expect(Datadog::Tracing).to have_received(:continue_trace!).with(trace_digest)
      end
    end

    context "when metadata is a JSON string" do
      let(:json_metadata) { metadata.to_json }

      it "parses the JSON and continues the trace" do
        described_class.continue_trace!(json_metadata)

        expect(Datadog::Tracing::TraceDigest).to have_received(:new).with(trace_id: 123, span_id: 456)
        expect(Datadog::Tracing).to have_received(:continue_trace!).with(trace_digest)
      end
    end

    context "when metadata is nil or invalid" do
      it "returns early without continuing the trace" do
        described_class.continue_trace!(nil)

        expect(Datadog::Tracing).not_to have_received(:continue_trace!)
      end
    end
  end
end
