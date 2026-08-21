require 'rails_helper'

RSpec.describe OpenAustralia::IngestPersonJob, type: :job do
  subject(:perform) { described_class.new.perform('10007') }

  let(:person) { create(:person) }

  before do
    allow(OpenAustralia::IngestPerson).to receive(:call).with(person_id: '10007').and_return(person)
    allow(OpenAustralia::Interpretation::RecordMembershipsAndPositions).to receive(:call)
  end

  it 'ingests the person' do
    perform
    expect(OpenAustralia::IngestPerson).to have_received(:call).with(person_id: '10007')
  end

  it 'runs Interpretation for the ingested person' do
    perform
    expect(OpenAustralia::Interpretation::RecordMembershipsAndPositions).to have_received(:call).with(person:)
  end

  context 'when ingest returns nil (no terms found for the person_id)' do
    let(:person) { nil }

    it 'does not run Interpretation' do
      perform
      expect(OpenAustralia::Interpretation::RecordMembershipsAndPositions).not_to have_received(:call)
    end
  end

  context 'when ingest raises a generic error' do
    before do
      allow(OpenAustralia::IngestPerson).to receive(:call).and_raise(StandardError, 'boom')
    end

    it 're-raises and logs an ApiLog entry' do
      expect { perform }.to raise_error(StandardError, 'boom').and change(ApiLog, :count).by(1)
    end
  end

  context 'when ingest raises OpenAustraliaRateLimitError (transient)' do
    before do
      allow(OpenAustralia::IngestPerson).to receive(:call).and_raise(OpenAustraliaRateLimitError, '429: slow down')
    end

    it 're-raises (so Sidekiq retries) and logs an ApiLog entry' do
      expect { perform }.to raise_error(OpenAustraliaRateLimitError).and change(ApiLog, :count).by(1)
    end
  end

  context 'when ingest raises a non-rate-limit OpenAustraliaApiError (deterministic, not retryable)' do
    before do
      allow(OpenAustralia::IngestPerson).to receive(:call).and_raise(OpenAustraliaApiError, 'getRepresentative: Unknown person ID')
    end

    it 'does not re-raise, but logs an ApiLog entry' do
      expect { perform }.not_to raise_error
      expect(ApiLog.count).to eq(1)
    end
  end
end
