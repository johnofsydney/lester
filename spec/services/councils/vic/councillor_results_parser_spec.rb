require 'rails_helper'

RSpec.describe Councils::Vic::CouncillorResultsParser, type: :service do
  subject(:call_service) { described_class.call(page) }

  context 'when the election has been declared' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared.html').read }

    it 'extracts the declared (last updated) date' do
      expect(call_service[:declared_date]).to eq(Date.new(2024, 11, 22))
    end

    it 'extracts each candidate name, stripping the (Nth elected) suffix, with no party' do
      expect(call_service[:candidates]).to eq(
        [
          { name: 'NICHOLAS, Sarah', party: '' },
          { name: 'ANDERSEN, John', party: '' },
          { name: 'RONCO, Jean-Pierre', party: '' }
        ]
      )
    end
  end

  context 'when the election has not yet been declared' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_not_declared.html').read }

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end

  context 'when the council is divided into wards' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared_wards.html').read }

    it 'extracts candidates from every ward, not just the first' do
      expect(call_service[:candidates]).to eq(
        [
          { name: 'DOWLING, Scott William', party: '' },
          { name: 'NGUYEN, Damien', party: '' }
        ]
      )
    end

    it 'still extracts the single page-level declared date' do
      expect(call_service[:declared_date]).to eq(Date.new(2024, 11, 22))
    end
  end

  context 'when the council also has a directly-elected Leadership Team contest' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared_with_leadership_team.html').read }

    it 'extracts only the Councillors contest, excluding the Lord Mayor and Deputy Lord Mayor' do
      expect(call_service[:candidates]).to eq(
        [
          { name: 'LOUEY, Kevin', party: '' },
          { name: 'GUEST, Owen', party: '' }
        ]
      )
    end
  end

  context 'when the council is under state-appointed administration' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_under_administration.html').read }

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end

  describe '.no_contest_expected?' do
    it 'is true for a council-under-administration page' do
      page = Rails.root.join('spec/fixtures/councils/vic/councillor_under_administration.html').read
      expect(described_class.no_contest_expected?(page)).to be(true)
    end

    it 'is false for a normal declared results page' do
      page = Rails.root.join('spec/fixtures/councils/vic/councillor_declared.html').read
      expect(described_class.no_contest_expected?(page)).to be(false)
    end

    it 'is false for a not-yet-declared page' do
      page = Rails.root.join('spec/fixtures/councils/vic/councillor_not_declared.html').read
      expect(described_class.no_contest_expected?(page)).to be(false)
    end
  end
end
