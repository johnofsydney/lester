require 'rails_helper'

RSpec.describe Councils::Qld::KnownCouncils, type: :service do
  let(:electorates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_electorates.json').read }
  let(:electorates_url) { format(described_class::ELECTORATES_URL, stub: '2024QLGE') }

  before do
    described_class.reset!
    allow(Councils::Qld::Elections).to receive(:latest_general).and_return(stub: '2024QLGE')
    allow(Councils::PageDownloader).to receive(:call).with(electorates_url).and_return(electorates_page)
  end

  describe '.resolve' do
    it 'resolves a numbered-division contest name to its council' do
      expect(described_class.resolve('Aurukun Shire Division 1')).to eq('Aurukun Shire')
    end

    it 'resolves a mayoral contest name to its council' do
      expect(described_class.resolve('Banana Shire')).to eq('Banana Shire')
    end

    it 'resolves a named-ward contest (Brisbane) via longest-prefix match, not a Division suffix' do
      expect(described_class.resolve('Brisbane City Bracken Ridge')).to eq('Brisbane City')
      expect(described_class.resolve('Brisbane City Calamvale')).to eq('Brisbane City')
    end

    it 'returns nil for a name matching no known council' do
      expect(described_class.resolve('Not A Real Council Division 1')).to be_nil
    end

    it 'fetches the electorates list only once across multiple calls' do
      described_class.resolve('Aurukun Shire Division 1')
      described_class.resolve('Banana Shire')

      expect(Councils::PageDownloader).to have_received(:call).once
    end

    it 'does no network fetch when an explicit name list is given via within:' do
      expect(described_class.resolve('Aurukun Shire Division 1', within: ['Aurukun Shire'])).to eq('Aurukun Shire')
      expect(Councils::PageDownloader).not_to have_received(:call)
    end
  end
end
