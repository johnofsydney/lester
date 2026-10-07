require 'rails_helper'

RSpec.describe NswStatePoliticians::Lc::FpByGrpParser, type: :service do
  let(:page) { File.read(Rails.root.join('spec/fixtures/nsw_state_politicians/lc_fp_by_grp.html')) }

  it 'maps each lettered group to its declared party name' do
    result = described_class.call(page)

    expect(result).to eq({ 'D' => 'LABOR', 'R' => 'THE GREENS' })
  end

  it 'excludes groups with no declared party name (ungrouped independents)' do
    result = described_class.call(page)

    expect(result).not_to have_key('A')
  end

  it 'excludes the trailing summary rows (UNGROUPED CANDIDATES, Total Formal Votes), which have no group letter' do
    result = described_class.call(page)

    expect(result.values).not_to include('UNGROUPED CANDIDATES', 'Total Formal Votes')
  end
end
