require 'rails_helper'

RSpec.describe Councils::Nsw::IngestByElectionResultsJob, type: :job do
  describe '#perform' do
    let(:archive_url) { described_class::ARCHIVE_URL }

    before do
      allow(Councils::PageDownloader).to receive(:call)
        .with(archive_url)
        .and_return(archive_page)
      allow(Councils::Nsw::ImportByElectionResultRowJob).to receive(:perform_in)
    end

    context 'when the archive page downloads and parses successfully' do
      let(:archive_page) { Rails.root.join('spec/fixtures/councils/nsw/local_election_results_archive.html').read }

      it 'enqueues an import job for every event with a modern report link' do
        described_class.new.perform

        expect(Councils::Nsw::ImportByElectionResultRowJob).to have_received(:perform_in)
          .with(
            kind_of(ActiveSupport::Duration),
            'LB2401',
            'https://results.elections.nsw.gov.au/LB2401/Berrigan/Councillor/DistributionOfPreferencesReport.html',
            'Berrigan Shire Council'
          )
      end
    end

    context 'when the archive page fails to download' do
      let(:archive_page) { nil }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /Failed to download/)
        expect(IngestSourceStatus.find_by(key: described_class.name).last_failure_at).to be_present
        expect(Councils::Nsw::ImportByElectionResultRowJob).not_to have_received(:perform_in)
      end
    end

    context 'when the archive page has no events' do
      let(:archive_page) { '<html><body>nothing</body></html>' }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform }.to raise_error(PermanentIngestError, %r{No NSW by-election/countback events found})
        expect(IngestSourceStatus.find_by(key: described_class.name).last_failure_at).to be_present
      end
    end
  end
end
