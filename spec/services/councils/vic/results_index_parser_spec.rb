require 'rails_helper'

RSpec.describe Councils::Vic::ResultsIndexParser, type: :service do
  subject(:call_service) { described_class.call(page) }

  let(:page) { Rails.root.join('spec/fixtures/councils/vic/index.html').read }

  it 'extracts each council name and results-page slug' do
    expect(call_service).to eq(
      [
        { name: 'Alpine Shire Council', slug: 'alpine-shire-council' },
        { name: 'Ararat Rural City Council', slug: 'ararat-rural-city-council' },
        { name: 'Ballarat City Council', slug: 'ballarat-city-council' }
      ]
    )
  end

  context 'when the page has no council links' do
    let(:page) { '<html><body><p>nothing here</p></body></html>' }

    it 'returns an empty array' do
      expect(call_service).to eq([])
    end
  end

  context 'when the same council is linked more than once' do
    let(:page) do
      <<~HTML
        <html><body>
          <a href="/results/council-election-results/2024-council-election-results/alpine-shire-council">Alpine Shire Council</a>
          <a href="/results/council-election-results/2024-council-election-results/alpine-shire-council">Alpine Shire Council</a>
        </body></html>
      HTML
    end

    it 'deduplicates by slug' do
      expect(call_service).to eq([{ name: 'Alpine Shire Council', slug: 'alpine-shire-council' }])
    end
  end
end
