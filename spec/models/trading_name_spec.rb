require 'rails_helper'

RSpec.describe TradingName do
  describe 'validations' do
    let(:group) { FactoryBot.create(:group, name: 'Acme Holdings') }

    it 'defaults source to ingest' do
      trading_name = group.trading_names.create!(name: 'Acme')
      expect(trading_name.source).to eq('ingest')
    end

    it 'rejects an unknown source' do
      trading_name = group.trading_names.build(name: 'Acme', source: 'guesswork')
      expect(trading_name).not_to be_valid
    end
  end

  describe '.sole_owner_for' do
    let!(:group) { FactoryBot.create(:group, name: 'Acme Holdings') }

    before { group.trading_names.create!(name: 'Acme') }

    it 'returns the sole owner of a matching trading name' do
      expect(described_class.sole_owner_for('Acme', owner_type: 'Group')).to eq(group)
    end

    it 'returns nil when no trading name matches' do
      expect(described_class.sole_owner_for('Nonexistent', owner_type: 'Group')).to be_nil
    end

    it 'does not match trading names belonging to the other owner type' do
      expect(described_class.sole_owner_for('Acme', owner_type: 'Person')).to be_nil
    end

    it 'raises AmbiguousName when multiple owners share the trading name' do
      other_group = FactoryBot.create(:group, name: 'Acme Industries')
      other_group.trading_names.create!(name: 'Acme')

      allow(NewRelic::Agent).to receive(:notice_error)

      expect { described_class.sole_owner_for('Acme', owner_type: 'Group') }
        .to raise_error(TradingName::AmbiguousName, /cannot disambiguate/)
    end

    it 'ignores a same-name trading name on the other owner type when resolving' do
      person = FactoryBot.create(:person, name: 'Acme Person')
      person.trading_names.create!(name: 'Acme')

      expect(described_class.sole_owner_for('Acme', owner_type: 'Group')).to eq(group)
    end
  end
end
