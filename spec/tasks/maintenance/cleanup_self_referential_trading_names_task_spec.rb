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
    before { allow(Maintenance::DeleteSelfReferentialTradingNameJob).to receive(:perform_async) }

    context 'when dry_run is true (default)' do
      it 'does not enqueue a deletion job' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        task.process(self_referential_group_trading_name)

        expect(Maintenance::DeleteSelfReferentialTradingNameJob).not_to have_received(:perform_async)
      end
    end

    context 'when dry_run is false' do
      it 'enqueues a deletion job for the trading name' do
        task = described_class.new.tap { |t| t.dry_run = false }

        task.process(self_referential_group_trading_name)

        expect(Maintenance::DeleteSelfReferentialTradingNameJob)
          .to have_received(:perform_async).with(self_referential_group_trading_name.id)
      end

      it 'does not delete anything itself' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(self_referential_group_trading_name) }.not_to change(TradingName, :count)
      end
    end
  end
end
