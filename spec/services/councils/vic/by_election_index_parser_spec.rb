require 'rails_helper'

RSpec.describe Councils::Vic::ByElectionIndexParser, type: :service do
  let(:page) { Rails.root.join('spec/fixtures/councils/vic/by_election_timeline.html').read }

  it 'returns every by-election and countback event across all year accordions' do
    expect(described_class.call(page)).to contain_exactly(
      {
        kind: :countback,
        council_description: 'Moira Shire Council',
        slug: '12dec-moira-shire-countback',
        date: Date.new(2022, 12, 12)
      },
      {
        kind: :by_election,
        council_description: 'Maroondah City Council, Wonga Ward',
        slug: 'maroondah-council-wonga-ward-by-election',
        date: Date.new(2022, 3, 12)
      },
      {
        kind: :countback,
        council_description: 'Example Shire Council',
        slug: '3may-example-shire-countback',
        date: Date.new(2021, 5, 3)
      }
    )
  end

  context 'when the page has no accordions' do
    let(:page) { '<html><body>nothing</body></html>' }

    it 'returns an empty array' do
      expect(described_class.call(page)).to eq([])
    end
  end
end
