require 'rails_helper'

RSpec.describe Councils::Vic::IngestByElectionResultsJob, type: :job do
  describe '#perform' do
    let(:timeline_url) { described_class::TIMELINE_URL }

    before do
      allow(Councils::PageDownloader).to receive(:call)
        .with(timeline_url)
        .and_return(timeline_page)
      allow(Councils::Vic::ImportByElectionResultRowJob).to receive(:perform_in)
    end

    context 'when the timeline page downloads and parses successfully' do
      let(:timeline_page) { Rails.root.join('spec/fixtures/councils/vic/by_election_timeline.html').read }

      it 'enqueues an import job for every event found, with kind stringified' do
        described_class.new.perform

        expect(Councils::Vic::ImportByElectionResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), '12dec-moira-shire-countback', 'countback', 'Moira Shire Council')
        expect(Councils::Vic::ImportByElectionResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'maroondah-council-wonga-ward-by-election', 'by_election', 'Maroondah City Council, Wonga Ward')
      end
    end

    context 'when the timeline page fails to download' do
      let(:timeline_page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /Failed to download/)
        expect(ApiLog.last.endpoint).to eq(timeline_url)
        expect(Councils::Vic::ImportByElectionResultRowJob).not_to have_received(:perform_in)
      end
    end

    context 'when the timeline page has no events' do
      let(:timeline_page) { '<html><body>nothing</body></html>' }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, %r{No VIC by-election/countback events found})
        expect(ApiLog.last.endpoint).to eq(timeline_url)
      end
    end
  end
end
