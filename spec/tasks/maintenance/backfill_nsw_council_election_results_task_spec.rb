require 'rails_helper'

RSpec.describe Maintenance::BackfillNswCouncilElectionResultsTask do
  let(:index_url) { "https://pastvtr.elections.nsw.gov.au/#{described_class::BACKFILL_ELECTION_ID}/index" }
  let(:index_page) { Rails.root.join('spec/fixtures/councils/nsw/index.html').read }

  before do
    allow(Councils::PageDownloader).to receive(:call).with(index_url).and_return(index_page)
  end

  describe '#collection' do
    it 'returns the councils parsed from the backfill election\'s index page' do
      task = described_class.new

      expect(task.collection).to include(
        { name: 'Albury City Council', slug: 'albury' },
        { name: 'Federation Council', slug: 'federation' }
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
    it 'enqueues Councils::Nsw::ImportCouncilResultRowJob with the backfill election id, spaced by collection position' do
      allow(Councils::Nsw::ImportCouncilResultRowJob).to receive(:perform_in)

      task = described_class.new
      council = task.collection.find { |c| c[:slug] == 'federation' }
      task.process(council)

      expected_delay = task.collection.index(council) * Councils::Nsw::IngestElectionResultsJob::IMPORT_SPACING
      expect(Councils::Nsw::ImportCouncilResultRowJob).to have_received(:perform_in)
        .with(expected_delay, 'Federation Council', 'federation', described_class::BACKFILL_ELECTION_ID)
    end
  end
end
