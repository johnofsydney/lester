require 'rails_helper'

RSpec.describe Councils::Vic::CycleIndexParser, type: :service do
  let(:page) { Rails.root.join('spec/fixtures/councils/vic/cycle_index.html').read }

  it 'returns every general cycle using the modern <year>-council-election-results slug' do
    expect(described_class.call(page)).to contain_exactly({ year: 2024 }, { year: 2020 })
  end

  it 'excludes single-council special elections and legacy cycles' do
    years = described_class.call(page).map { |cycle| cycle[:year] }

    expect(years).not_to include(2021, 2017)
  end

  context 'when the page has no matching links' do
    let(:page) { '<html><body>nothing</body></html>' }

    it 'returns an empty array' do
      expect(described_class.call(page)).to eq([])
    end
  end
end
