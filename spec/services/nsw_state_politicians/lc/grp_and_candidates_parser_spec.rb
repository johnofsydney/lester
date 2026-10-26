require 'rails_helper'

RSpec.describe NswStatePoliticians::Lc::GrpAndCandidatesParser, type: :service do
  let(:page) { File.read(Rails.root.join('spec/fixtures/nsw_state_politicians/lc_grp_and_candidates.html')) }

  it 'parses every candidate row, attaching the preceding group header\'s letter' do
    result = described_class.call(page)

    expect(result).to eq([
                           { name: 'SHELTON Lyle', group_letter: 'A', status: 'EXCLUDED', position: '266', count: '284' },
                           { name: 'HOUSSOS Courtney', group_letter: 'D', status: 'ELECTED', position: '1', count: '1' },
                           { name: 'SOME Otherperson', group_letter: 'D', status: 'EXCLUDED', position: '2', count: '150' }
                         ])
  end

  it 'does not emit a row for the group header itself' do
    result = described_class.call(page)

    expect(result.map { |c| c[:name] }).not_to include('', 'A', 'D')
  end
end
