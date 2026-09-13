require 'rails_helper'

RSpec.describe Groups::DeleteDuplicates do
  before { allow(Cache::BuildGroupCachedDataJob).to receive(:perform_async) }

  describe '#call' do
    context 'with three groups sharing a name' do
      let!(:keeper) { FactoryBot.create(:group, name: 'Acme Foundation') }
      let!(:dup1) { FactoryBot.create(:group, name: 'Acme Foundation') }
      let!(:dup2) { FactoryBot.create(:group, name: 'Acme Foundation') }

      context 'when dry_run is true (default)' do
        it 'does not merge or destroy anyone' do
          expect { described_class.new.call }.not_to change(Group, :count)
          expect(Group.exists?(dup1.id)).to be(true)
          expect(Group.exists?(dup2.id)).to be(true)
        end
      end

      context 'when dry_run is false' do
        it 'folds every duplicate into the lowest-id keeper' do
          expect { described_class.new.call(dry_run: false) }.to change(Group, :count).by(-2)

          expect(Group.exists?(keeper.id)).to be(true)
          expect(Group.exists?(dup1.id)).to be(false)
          expect(Group.exists?(dup2.id)).to be(false)
        end
      end
    end

    context 'with no duplicates' do
      it 'does nothing' do
        FactoryBot.create(:group, name: 'Solo Group')

        expect { described_class.new.call(dry_run: false) }.not_to change(Group, :count)
      end
    end
  end

  describe '#duplicate_ids' do
    it 'returns every duplicate id except each name-group keeper' do
      keeper = FactoryBot.create(:group, name: 'Acme Foundation')
      dup1 = FactoryBot.create(:group, name: 'Acme Foundation')
      dup2 = FactoryBot.create(:group, name: 'Acme Foundation')
      FactoryBot.create(:group, name: 'Solo Group')

      expect(described_class.new.duplicate_ids).to contain_exactly(dup1.id, dup2.id)
      expect(described_class.new.duplicate_ids).not_to include(keeper.id)
    end
  end

  describe '#keeper_for' do
    let!(:keeper) { FactoryBot.create(:group, name: 'Acme Foundation') }
    let!(:dup) { FactoryBot.create(:group, name: 'Acme Foundation') }

    it 'returns the lowest-id same-name group when no block is given' do
      expect(described_class.new.keeper_for(dup)).to eq(keeper)
    end

    it 'returns nil when there is no same-name group' do
      solo = FactoryBot.create(:group, name: 'Solo Group')

      expect(described_class.new.keeper_for(solo)).to be_nil
    end

    it 'yields each same-name candidate in id order and returns the first the block accepts' do
      other_keeper = FactoryBot.create(:group, name: 'Acme Foundation')

      result = described_class.new.keeper_for(dup) { |_group, candidate| candidate == other_keeper }

      expect(result).to eq(other_keeper)
    end

    it 'returns nil when the block rejects every candidate' do
      result = described_class.new.keeper_for(dup) { |_group, _candidate| false }

      expect(result).to be_nil
    end
  end
end
