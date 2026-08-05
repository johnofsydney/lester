require 'rails_helper'

RSpec.describe Councils::Nsw::ResultsIndexParser, type: :service do
  subject(:call_service) { described_class.call(page) }

  let(:page) { Rails.root.join('spec/fixtures/councils/nsw/index.html').read }

  it 'extracts each council name and results-page slug' do
    expect(call_service).to eq(
      [
        { name: 'Albury City Council', slug: 'albury' },
        { name: 'Armidale Regional Council', slug: 'armidale' },
        { name: 'Federation Council', slug: 'federation' }
      ]
    )
  end

  context 'when the page has no council links' do
    let(:page) { '<html><body><p>nothing here</p></body></html>' }

    it 'returns an empty array' do
      expect(call_service).to eq([])
    end
  end
end
