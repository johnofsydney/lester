require 'rails_helper'

RSpec.describe Councils::Qld::ImportElectionResultsJob, type: :job do
  describe '#perform' do
    let(:stub) { '2024QLGE' }

    before do
      allow(Councils::Qld::RecordContestResultJob).to receive(:perform_async)
    end

    context 'when the stub has parseable declared results' do
      before do
        allow(Councils::Qld::DeclaredResultsParser).to receive(:call).with(stub).and_return(
          [
            {
              council_name: 'Aurukun Shire',
              contest_name: 'Aurukun Shire',
              contest_type: 'mayor',
              candidates: [{ name: 'BANDICOOTCHA, Barbara Sue', party: nil }],
              declared_date: Date.new(2024, 3, 28),
              source_url: 'https://resultsdata.elections.qld.gov.au/2024QLGE-declared_candidates.json'
            }
          ]
        )
      end

      it 'fans out one RecordContestResultJob per parsed contest' do
        described_class.new.perform(stub)

        expect(Councils::Qld::RecordContestResultJob).to have_received(:perform_async).with(
          stub, 'Aurukun Shire', 'Aurukun Shire', 'mayor',
          [{ 'name' => 'BANDICOOTCHA, Barbara Sue', 'party' => nil }],
          '2024-03-28',
          'https://resultsdata.elections.qld.gov.au/2024QLGE-declared_candidates.json'
        )
      end
    end

    context 'when nothing has been declared yet for this stub' do
      before { allow(Councils::Qld::DeclaredResultsParser).to receive(:call).with(stub).and_return([]) }

      it 'does not raise and enqueues nothing' do
        expect { described_class.new.perform(stub) }.not_to raise_error
        expect(Councils::Qld::RecordContestResultJob).not_to have_received(:perform_async)
      end
    end

    context 'when parsing raises' do
      before { allow(Councils::Qld::DeclaredResultsParser).to receive(:call).with(stub).and_raise('boom') }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(stub) }.to raise_error('boom')
        expect(ApiLog.last.endpoint).to eq(stub)
      end
    end
  end
end
