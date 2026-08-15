require 'rails_helper'

RSpec.describe Councils::Vic::IngestElectionResultsJob, type: :job do
  describe '#perform' do
    let(:election_year) { Councils::Vic::Elections.latest[:year] }
    let(:index_url) { "https://www.vec.vic.gov.au/results/council-election-results/#{election_year}-council-election-results" }

    before do
      allow(Councils::PageDownloader).to receive(:call)
        .with(index_url)
        .and_return(index_page)
      allow(Councils::Vic::ImportCouncilResultRowJob).to receive(:perform_in)
    end

    context 'when the index page downloads and parses successfully' do
      let(:index_page) { Rails.root.join('spec/fixtures/councils/vic/index.html').read }

      it 'enqueues an import job for every council found' do
        described_class.new.perform

        expect(Councils::Vic::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Alpine Shire Council', 'alpine-shire-council', election_year)
        expect(Councils::Vic::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Ararat Rural City Council', 'ararat-rural-city-council', election_year)
        expect(Councils::Vic::ImportCouncilResultRowJob).to have_received(:perform_in)
          .with(kind_of(ActiveSupport::Duration), 'Ballarat City Council', 'ballarat-city-council', election_year)
      end
    end

    context 'when the index page fails to download' do
      let(:index_page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /Failed to download/)
        expect(ApiLog.last.endpoint).to eq(index_url)
        expect(Councils::Vic::ImportCouncilResultRowJob).not_to have_received(:perform_in)
      end
    end

    context 'when the index page has no councils' do
      let(:index_page) { '<html><body>nothing</body></html>' }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /No councils found/)
        expect(ApiLog.last.endpoint).to eq(index_url)
      end
    end
  end
end
