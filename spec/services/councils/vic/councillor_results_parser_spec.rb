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
end
