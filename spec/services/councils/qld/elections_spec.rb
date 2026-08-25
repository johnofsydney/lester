require 'rails_helper'

RSpec.describe Councils::Qld::Elections, type: :service do
  let(:elections_page) { Rails.root.join('spec/fixtures/councils/qld/elections.json').read }

  before do
    allow(Councils::PageDownloader).to receive(:call)
      .with(described_class::ELECTIONS_URL)
      .and_return(elections_page)
  end

  describe '#local' do
    it 'returns only QLD local election types, excluding state elections' do
      stubs = described_class.new.local.map { |election| election[:stub] }

      expect(stubs).to contain_exactly('lga2020', '2024QLGE', 'MSC24')
    end
  end

  describe '#latest_general' do
    it 'returns the most recent Local Quadrennial election by election_day, not the current flag' do
      expect(described_class.new.latest_general).to include(stub: '2024QLGE', election_day: Date.new(2024, 3, 16))
    end
  end

  context 'when the index fails to download' do
    let(:elections_page) { nil }

    it 'raises' do
      expect { described_class.new.local }.to raise_error(RuntimeError, /Failed to download/)
    end
  end
end
