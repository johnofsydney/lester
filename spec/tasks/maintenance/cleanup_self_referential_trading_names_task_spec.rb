require 'rails_helper'

RSpec.describe Maintenance::CleanupSelfReferentialTradingNamesTask do
  let!(:group) { FactoryBot.create(:group, name: 'Banana Shire Council') }
  let!(:self_referential_group_trading_name) { TradingName.create!(owner: group, name: 'Banana Shire Council') }
  let!(:distinct_group_trading_name) { TradingName.create!(owner: group, name: 'BSC') }

  let!(:person) { FactoryBot.create(:person, name: 'Jane Smith') }
  let!(:self_referential_person_trading_name) { TradingName.create!(owner: person, name: 'Jane Smith') }
  let!(:distinct_person_trading_name) { TradingName.create!(owner: person, name: 'J Smith') }

  describe '#collection' do
    it 'includes trading names identical to their Group owner\'s name' do
      expect(described_class.collection).to include(self_referential_group_trading_name)
    end

    it 'includes trading names identical to their Person owner\'s name' do
      expect(described_class.collection).to include(self_referential_person_trading_name)
    end

    it 'excludes trading names distinct from their owner\'s name' do
      expect(described_class.collection).not_to include(distinct_group_trading_name, distinct_person_trading_name)
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      expect(described_class.count).to eq(2)
    end
  end

  describe '#process' do
    context 'when dry_run is true (default)' do
      it 'does not delete anything' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        expect { task.process(self_referential_group_trading_name) }.not_to change(TradingName, :count)
      end
    end

    context 'when dry_run is false' do
      it 'destroys the trading name' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(self_referential_group_trading_name) }.to change(TradingName, :count).by(-1)
        expect(TradingName.exists?(self_referential_group_trading_name.id)).to be(false)
      end

      it 'leaves distinct trading names untouched' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(self_referential_group_trading_name) }.not_to(change { TradingName.exists?(distinct_group_trading_name.id) })
      end
    end
  end
end
