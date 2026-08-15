require 'rails_helper'

RSpec.describe Maintenance::BackfillVicCouncilElectionResultsTask do
  let(:index_url) { "https://www.vec.vic.gov.au/results/council-election-results/#{described_class::BACKFILL_ELECTION_YEAR}-council-election-results" }
  let(:index_page) { Rails.root.join('spec/fixtures/councils/vic/index.html').read }

  before do
    allow(Councils::PageDownloader).to receive(:call).with(index_url).and_return(index_page)
  end

  describe '#collection' do
    it 'returns the councils parsed from the backfill election\'s index page' do
      task = described_class.new

      expect(task.collection).to include(
        { name: 'Alpine Shire Council', slug: 'alpine-shire-council' },
        { name: 'Ballarat City Council', slug: 'ballarat-city-council' }
      )
    end

    context 'when the index page fails to download' do
      let(:index_page) { nil }

      it 'raises' do
        expect { described_class.new.collection }.to raise_error(RuntimeError, /Failed to download/)
      end
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      task = described_class.new
      expect(task.count).to eq(task.collection.size)
    end
  end

  describe '#process' do
    it 'delegates to Councils::Vic::ImportCouncilResultRowJob with the backfill election year' do
      job = instance_double(Councils::Vic::ImportCouncilResultRowJob)
      allow(Councils::Vic::ImportCouncilResultRowJob).to receive(:new).and_return(job)
      allow(job).to receive(:perform)

      described_class.new.process({ name: 'Alpine Shire Council', slug: 'alpine-shire-council' })

      expect(job).to have_received(:perform).with('Alpine Shire Council', 'alpine-shire-council', described_class::BACKFILL_ELECTION_YEAR)
    end
  end
end
