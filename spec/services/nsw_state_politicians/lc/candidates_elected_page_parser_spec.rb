require 'rails_helper'

RSpec.describe NswStatePoliticians::Lc::CandidatesElectedPageParser, type: :service do
  let(:page) { File.read(Rails.root.join('spec/fixtures/nsw_state_politicians/lc_candidates_elected.html')) }

  it 'parses one row per elected member, including joint-ticket group names' do
    result = described_class.call(page)

    expect(result).to eq([
                           { name: 'HOUSSOS Courtney', group_letter: 'D', party: 'LABOR', elected_at_count: '1' },
                           { name: 'MACLAREN-JONES Natasha', group_letter: 'I', party: 'LIBERAL / THE NATIONALS', elected_at_count: '1' },
                           { name: 'FAEHRMANN Cate', group_letter: 'R', party: 'THE GREENS', elected_at_count: '1' }
                         ])
  end
end
