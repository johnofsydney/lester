require 'rails_helper'

RSpec.describe Councils::Nsw::IngestElectionResultsJob, type: :job do
  describe '#perform' do
    let(:election_id) { Councils::Nsw::Elections.latest[:id] }
    let(:index_url) { "https://pastvtr.elections.nsw.gov.au/#{election_id}/index" }

    before do
      Councils::Nsw::Elections.reset!
      allow(Councils::PageDownloader).to receive(:call)
        .with(Councils::Nsw::Elections::ROOT_URL)
        .and_return(Rails.root.join('spec/fixtures/councils/nsw/pastvtr_root.html').read)
      allow(Councils::PageDownloader).to receive(:call)
        .with(index_url)
        .and_return(index_page)
      allow(Councils::Nsw::ImportCouncilResultRowJob).to receive(:perform_in)
    end

    context 'when the index page downloads and parses successfully' do
      let(:index_page) { Rails.root.join('spec/fixtures/councils/nsw/index.html').read }

      it 'enqueues an import job for every council found' do
        described_class.new.perform

        expect(Councils::Nsw::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Albury City Council', 'albury', election_id)
        expect(Councils::Nsw::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Armidale Regional Council', 'armidale', election_id)
        expect(Councils::Nsw::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Federation Council', 'federation', election_id)
      end
    end

    context 'when the index page fails to download' do
      let(:index_page) { nil }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /Failed to download/)
        expect(IngestSourceStatus.find_by(key: described_class.name).last_failure_at).to be_present
        expect(Councils::Nsw::ImportCouncilResultRowJob).not_to have_received(:perform_in)
      end
    end

    context 'when the index page has no councils' do
      let(:index_page) { '<html><body>nothing</body></html>' }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /No councils found/)
        expect(IngestSourceStatus.find_by(key: described_class.name).last_failure_at).to be_present
      end
    end
  end
end
