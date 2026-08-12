require 'rails_helper'

RSpec.describe Councils::Nsw::CouncillorResultsParser, type: :service do
  subject(:call_service) { described_class.call(page) }

  context 'when the election has been declared' do
    let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }

    it 'extracts the declared date' do
      expect(call_service[:declared_date]).to eq(Date.new(2024, 10, 1))
    end

    it 'extracts each candidate name and party' do
      expect(call_service[:candidates]).to eq(
        [
          { name: 'Derek SCHOEN', party: 'Independent' },
          { name: 'Darren CAMERON', party: 'Australian Labor Party (NSW Branch)' },
          { name: 'Geoff HUDSON', party: 'The Greens NSW' },
          { name: 'Andrew KENNEDY', party: '' }
        ]
      )
    end
  end

  context 'when the election has not yet been declared' do
    let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_not_declared.html').read }

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end
end
