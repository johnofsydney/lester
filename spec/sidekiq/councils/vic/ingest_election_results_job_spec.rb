require 'rails_helper'

RSpec.describe Councils::Vic::IngestElectionResultsJob, type: :job do
  describe '#perform' do
    before do
      allow(Councils::PageDownloader).to receive(:call)
        .with(described_class::INDEX_URL)
        .and_return(index_page)
      allow(Councils::Vic::ImportCouncilResultRowJob).to receive(:perform_in)
    end

    context 'when the index page downloads and parses successfully' do
      let(:index_page) { Rails.root.join('spec/fixtures/councils/vic/index.html').read }

      it 'enqueues an import job for every council found' do
        described_class.new.perform

        expect(Councils::Vic::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Alpine Shire Council', 'alpine-shire-council')
        expect(Councils::Vic::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Ararat Rural City Council', 'ararat-rural-city-council')
        expect(Councils::Vic::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Ballarat City Council', 'ballarat-city-council')
      end
    end

    context 'when the index page fails to download' do
      let(:index_page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /Failed to download/)
        expect(ApiLog.last.endpoint).to eq(described_class::INDEX_URL)
        expect(Councils::Vic::ImportCouncilResultRowJob).not_to have_received(:perform_in)
      end
    end

    context 'when the index page has no councils' do
      let(:index_page) { '<html><body>nothing</body></html>' }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /No councils found/)
        expect(ApiLog.last.endpoint).to eq(described_class::INDEX_URL)
      end
    end
  end
end
