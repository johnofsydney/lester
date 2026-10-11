require 'rails_helper'

RSpec.describe Councils::Nsw::CycleIndexParser, type: :service do
  let(:page) { Rails.root.join('spec/fixtures/councils/nsw/pastvtr_root.html').read }

  it 'returns every modern LG cycle listed under Local Government Election Results' do
    expect(described_class.call(page)).to contain_exactly(
      { id: 'LG2401', year: 2024 },
      { id: 'LG2101', year: 2021 }
    )
  end

  it 'excludes legacy LGE cycles and state election cycles' do
    ids = described_class.call(page).map { |cycle| cycle[:id] }

    expect(ids).not_to include('LGE2017', 'LGE2016', 'LGE2012', 'LGE2008', 'SG2301', 'SGE1901')
  end

  context 'when the page has no Local Government Election Results heading' do
    let(:page) { '<html><body>nothing</body></html>' }

    it 'returns an empty array' do
      expect(described_class.call(page)).to eq([])
    end
  end
end
