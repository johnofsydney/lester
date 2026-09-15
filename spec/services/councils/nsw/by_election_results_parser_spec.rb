require 'rails_helper'

RSpec.describe Councils::Nsw::ByElectionResultsParser, type: :service do
  let(:page) { Rails.root.join('spec/fixtures/councils/nsw/by_election_declared.html').read }

  it 'returns the elected candidate (reordered to Given Surname) and the report\'s last-updated date' do
    expect(described_class.call(page)).to eq(
      declared_date: Date.new(2024, 12, 9),
      candidates: [{ name: 'Sharon DENNIS', party: '' }]
    )
  end

  context 'when there is no Elected row' do
    let(:page) { '<html><body><table><tr class="generalRow"><td>HUMPHRIES Myles</td></tr></table></body></html>' }

    it 'returns nil' do
      expect(described_class.call(page)).to be_nil
    end
  end
end
