require 'rails_helper'

RSpec.describe Councils::Nsw::ResultsPageParser, type: :service do
  subject(:call_service) { described_class.call(page) }

  context 'when the council is elected at-large (no wards)' do
    let(:page) { Rails.root.join('spec/fixtures/councils/nsw/results_single.html').read }

    it 'returns the single councillor path' do
      expect(call_service).to eq(['councillor'])
    end
  end

  context 'when the council is divided into wards' do
    let(:page) { Rails.root.join('spec/fixtures/councils/nsw/results_wards.html').read }

    it 'returns each ward councillor path' do
      expect(call_service).to eq(['ward-1/councillor', 'ward-2/councillor'])
    end
  end

  context 'when the council also has a separate mayoral contest' do
    let(:page) { Rails.root.join('spec/fixtures/councils/nsw/results_with_mayor.html').read }

    it 'returns only the ward councillor paths, ignoring the mayoral contest' do
      expect(call_service).to eq(['ward-a/councillor', 'ward-b/councillor'])
    end
  end

  context 'when the page has no Councillors contest row' do
    let(:page) { '<html><body><p>nothing here</p></body></html>' }

    it 'returns an empty array' do
      expect(call_service).to eq([])
    end
  end

  context 'when the council was under administration for this cycle' do
    let(:page) { Rails.root.join('spec/fixtures/councils/nsw/results_in_administration.html').read }

    it 'returns an empty array' do
      expect(call_service).to eq([])
    end
  end

  describe '.in_administration?' do
    it 'is true for a council-in-administration page' do
      page = Rails.root.join('spec/fixtures/councils/nsw/results_in_administration.html').read
      expect(described_class.in_administration?(page)).to be(true)
    end

    it 'is false for a normal results page' do
      page = Rails.root.join('spec/fixtures/councils/nsw/results_single.html').read
      expect(described_class.in_administration?(page)).to be(false)
    end
  end
end
