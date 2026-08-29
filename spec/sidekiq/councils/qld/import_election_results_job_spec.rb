require 'rails_helper'

RSpec.describe Councils::Qld::ImportElectionResultsJob, type: :job do
  describe '#perform' do
    let(:stub) { '2024QLGE' }
    let(:declared_candidates_url) { format(described_class::DECLARED_CANDIDATES_URL, stub:) }
    let(:electorates_url) { format(described_class::ELECTORATES_URL, stub:) }

    before do
      allow(Councils::Qld::RecordContestResultJob).to receive(:perform_async)
      allow(Councils::PageDownloader).to receive(:call).with(declared_candidates_url).and_return(declared_candidates_page)
      allow(Councils::PageDownloader).to receive(:call).with(electorates_url).and_return(electorates_page)
      allow(Councils::Qld::KnownCouncils).to receive(:names).and_return(['Aurukun Shire', 'Banana Shire', 'Brisbane City', 'Ipswich City'])
    end

    context 'when both JSON files download and parse successfully' do
      let(:declared_candidates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_declared_candidates.json').read }
      let(:electorates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_electorates.json').read }

      it 'fans out one RecordContestResultJob per parsed contest' do
        described_class.new.perform(stub)

        expect(Councils::Qld::RecordContestResultJob).to have_received(:perform_async).with(
          stub, 'Aurukun Shire', 'Aurukun Shire', 'mayor',
          [{ 'name' => 'BANDICOOTCHA, Barbara Sue', 'party' => nil }],
          '2024-03-28',
          declared_candidates_url
        )
      end
    end

    context 'when the declared-candidates JSON fails to download' do
      let(:declared_candidates_page) { nil }
      let(:electorates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_electorates.json').read }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(stub) }.to raise_error(RuntimeError, /Failed to download QLD declared candidates/)
        expect(ApiLog.last.endpoint).to eq(stub)
        expect(Councils::Qld::RecordContestResultJob).not_to have_received(:perform_async)
      end
    end

    context 'when the electorates JSON fails to download' do
      let(:declared_candidates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_declared_candidates.json').read }
      let(:electorates_page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(stub) }.to raise_error(RuntimeError, /Failed to download QLD electorates/)
        expect(ApiLog.last.endpoint).to eq(stub)
      end
    end
  end
end
