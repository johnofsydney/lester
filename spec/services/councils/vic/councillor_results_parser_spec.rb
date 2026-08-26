require 'rails_helper'

RSpec.describe Councils::Vic::CouncillorResultsParser, type: :service do
  subject(:call_service) { described_class.call(page) }

  context 'when the election has been declared' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared.html').read }

    it 'extracts the declared (last updated) date' do
      expect(call_service[:declared_date]).to eq(Date.new(2024, 11, 22))
    end

    it 'extracts each candidate name, stripping the (Nth elected) suffix, with no party, titled Councillor' do
      expect(call_service[:candidates]).to eq(
        [
          { name: 'NICHOLAS, Sarah', party: '', title: 'Councillor' },
          { name: 'ANDERSEN, John', party: '', title: 'Councillor' },
          { name: 'RONCO, Jean-Pierre', party: '', title: 'Councillor' }
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
          { name: 'DOWLING, Scott William', party: '', title: 'Councillor' },
          { name: 'NGUYEN, Damien', party: '', title: 'Councillor' }
        ]
      )
    end

    it 'still extracts the single page-level declared date' do
      expect(call_service[:declared_date]).to eq(Date.new(2024, 11, 22))
    end
  end

  context 'when the council also has a directly-elected Leadership Team contest' do
    let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared_with_leadership_team.html').read }

    it 'extracts the Lord Mayor and Deputy Lord Mayor, titled by their role, alongside the Councillors' do
      expect(call_service[:candidates]).to eq(
        [
          { name: 'REECE, Nick', party: '', title: 'Lord Mayor' },
          { name: 'CAMPBELL, Roshena', party: '', title: 'Deputy Lord Mayor' },
          { name: 'LOUEY, Kevin', party: '', title: 'Councillor' },
          { name: 'GUEST, Owen', party: '', title: 'Councillor' }
        ]
      )
    end
  end
end
