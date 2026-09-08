require 'rails_helper'

RSpec.describe NswStatePoliticians::La::ElectedPageParser, type: :service do
  let(:page) { File.read(Rails.root.join('spec/fixtures/nsw_state_politicians/la_elected.html')) }

  it 'parses one row per electorate winner' do
    result = described_class.call(page)

    expect(result).to eq([
                           { electorate: 'Albury', name: 'CLANCY Justin', party: 'The Liberal Party of Australia, New South Wales Division' },
                           { electorate: 'Auburn', name: 'VOLTZ Lynda', party: 'Australian Labor Party (NSW Branch)' }
                         ])
  end
end
