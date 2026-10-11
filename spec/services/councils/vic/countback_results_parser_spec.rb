require 'rails_helper'

RSpec.describe Councils::Vic::CountbackResultsParser, type: :service do
  let(:page) { Rails.root.join('spec/fixtures/councils/vic/countback_declared.html').read }

  it 'returns the elected candidate and the countback date' do
    expect(described_class.call(page)).to eq(
      declared_date: Date.new(2022, 12, 12),
      candidates: [{ name: 'BUCK, Wendy', party: '' }]
    )
  end

  context 'when there is no Elected row' do
    let(:page) { '<html><body><table><tr><th>Vacancy date</th><td>3 November 2022</td></tr></table></body></html>' }

    it 'returns nil' do
      expect(described_class.call(page)).to be_nil
    end
  end
end
