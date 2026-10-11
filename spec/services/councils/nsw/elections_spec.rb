require 'rails_helper'

RSpec.describe Councils::Nsw::Elections, type: :service do
  let(:root_page) { Rails.root.join('spec/fixtures/councils/nsw/pastvtr_root.html').read }

  before do
    described_class.reset!
    allow(Councils::PageDownloader).to receive(:call)
      .with(described_class::ROOT_URL)
      .and_return(root_page)
  end

  describe '.latest' do
    it 'returns the cycle with the highest year' do
      expect(described_class.latest).to eq(id: 'LG2401', year: 2024)
    end
  end

  describe '.find' do
    it 'returns the matching cycle' do
      expect(described_class.find('LG2101')).to eq(id: 'LG2101', year: 2021)
    end

    it 'raises for an unknown election_id' do
      expect { described_class.find('LG9999') }.to raise_error(ArgumentError, /Unknown NSW election_id/)
    end
  end

  describe 'caching' do
    it 'fetches the root index only once across multiple calls' do
      described_class.latest
      described_class.find('LG2101')

      expect(Councils::PageDownloader).to have_received(:call).once
    end
  end

  context 'when the index fails to download' do
    let(:root_page) { nil }

    it 'raises' do
      expect { described_class.latest }.to raise_error(RuntimeError, /Failed to download/)
    end
  end
end
