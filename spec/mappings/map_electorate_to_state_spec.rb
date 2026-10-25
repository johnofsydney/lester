require 'rails_helper'

RSpec.describe MapElectorateToState do
  describe '.lookup' do
    it 'returns the state for a known electorate name' do
      expect(described_class.lookup('Sydney')).to eq('NSW')
      expect(described_class.lookup('Melbourne')).to eq('VIC')
      expect(described_class.lookup('Canberra')).to eq('ACT')
    end

    it 'is case-sensitive and exact-match only' do
      expect(described_class.lookup('sydney')).to be_nil
      expect(described_class.lookup('Sydney ')).to be_nil
    end

    it 'returns nil for an unknown electorate name' do
      expect(described_class.lookup('Not A Real Electorate')).to be_nil
    end
  end
end
