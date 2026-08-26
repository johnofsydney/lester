require 'rails_helper'

RSpec.describe NswStatePoliticians::La::FpSummaryParser, type: :service do
  let(:page) { File.read(Rails.root.join('spec/fixtures/nsw_state_politicians/la_fp_summary.html')) }

  it 'parses every candidate row, including unsuccessful and independent candidates' do
    result = described_class.call(page)

    expect(result).to eq([
                           { name: 'VOLTZ Lynda', party: 'Australian Labor Party (NSW Branch)' },
                           { name: 'ASGARI Masoomeh', party: 'The Greens NSW' },
                           { name: 'DAOUD Jamal', party: '' },
                           { name: 'MORKOS DOUAIHY Julie', party: 'Liberal Democratic Party' }
                         ])
  end

  it 'excludes the trailing TOTAL FORMAL VOTES row' do
    result = described_class.call(page)

    expect(result.map { |c| c[:name] }).not_to include('TOTAL FORMAL VOTES')
  end
end
