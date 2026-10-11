require 'rails_helper'

RSpec.describe Councils::Vic::Elections, type: :service do
  let(:index_page) { Rails.root.join('spec/fixtures/councils/vic/cycle_index.html').read }

  before do
    described_class.reset!
    allow(Councils::PageDownloader).to receive(:call)
      .with(described_class::INDEX_URL)
      .and_return(index_page)
  end

  describe '.latest' do
    it 'returns the cycle with the highest year, with its polling date computed' do
      expect(described_class.latest).to eq(year: 2024, election_date: Date.new(2024, 10, 26))
    end
  end

  describe '.find' do
    it 'returns the matching cycle with its polling date computed' do
      expect(described_class.find(2020)).to eq(year: 2020, election_date: Date.new(2020, 10, 24))
    end

    it 'raises for an unknown election_year' do
      expect { described_class.find(1999) }.to raise_error(ArgumentError, /Unknown VIC election_year/)
    end
  end

  describe '.latest?' do
    it 'is true for the latest year and false otherwise' do
      expect(described_class.latest?(2024)).to be(true)
      expect(described_class.latest?(2020)).to be(false)
    end
  end

  describe 'caching' do
    it 'fetches the index only once across multiple calls' do
      described_class.latest
      described_class.find(2020)

      expect(Councils::PageDownloader).to have_received(:call).once
    end
  end

  context 'when the index fails to download' do
    let(:index_page) { nil }

    it 'raises' do
      expect { described_class.latest }.to raise_error(RuntimeError, /Failed to download/)
    end
  end
end
