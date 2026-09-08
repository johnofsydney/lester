require 'rails_helper'

RSpec.describe NswStatePoliticians::La::ResultsIndexParser, type: :service do
  let(:page) { File.read(Rails.root.join('spec/fixtures/nsw_state_politicians/la_results_index.html')) }

  it 'extracts each electorate slug from its fp_summary link' do
    expect(described_class.call(page)).to eq(%w[auburn badgerys-creek])
  end
end
