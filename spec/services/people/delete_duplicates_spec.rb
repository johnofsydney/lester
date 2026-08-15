require 'rails_helper'

RSpec.describe People::DeleteDuplicates do
  before { allow(Cache::BuildPersonCachedDataJob).to receive(:perform_async) }

  describe '#call' do
    context 'with three people sharing a name' do
      let!(:keeper) { FactoryBot.create(:person, name: 'Adam Benson') }
      let!(:dup1) { FactoryBot.create(:person, name: 'Adam Benson') }
      let!(:dup2) { FactoryBot.create(:person, name: 'Adam Benson') }

      context 'when dry_run is true (default)' do
        it 'does not merge or destroy anyone' do
          expect { described_class.new.call(scope: Person.all) }.not_to change(Person, :count)
          expect(Person.exists?(dup1.id)).to be(true)
          expect(Person.exists?(dup2.id)).to be(true)
        end
      end

      context 'when dry_run is false' do
        it 'folds every duplicate into the lowest-id keeper' do
          expect { described_class.new.call(dry_run: false, scope: Person.all) }.to change(Person, :count).by(-2)

          expect(Person.exists?(keeper.id)).to be(true)
          expect(Person.exists?(dup1.id)).to be(false)
          expect(Person.exists?(dup2.id)).to be(false)
        end
      end
    end

    context 'with no duplicates' do
      it 'does nothing' do
        FactoryBot.create(:person, name: 'Solo Person')

        expect { described_class.new.call(dry_run: false, scope: Person.all) }.not_to change(Person, :count)
      end
    end

    context 'with a scope' do
      let!(:in_scope_keeper) { FactoryBot.create(:person, name: 'Scoped Duplicate') }
      let!(:in_scope_dup) { FactoryBot.create(:person, name: 'Scoped Duplicate') }
      let!(:out_of_scope_dup) { FactoryBot.create(:person, name: 'Unscoped Duplicate') }

      before { FactoryBot.create(:person, name: 'Unscoped Duplicate') }

      it 'only merges duplicates within the given scope' do
        scope = Person.where(id: [in_scope_keeper.id, in_scope_dup.id])

        expect { described_class.new.call(dry_run: false, scope:) }.to change(Person, :count).by(-1)

        expect(Person.exists?(in_scope_keeper.id)).to be(true)
        expect(Person.exists?(in_scope_dup.id)).to be(false)
        expect(Person.exists?(out_of_scope_dup.id)).to be(true)
      end
    end
  end

  describe '#duplicate_ids' do
    it 'returns every duplicate id except each name-group keeper' do
      keeper = FactoryBot.create(:person, name: 'Adam Benson')
      dup1 = FactoryBot.create(:person, name: 'Adam Benson')
      dup2 = FactoryBot.create(:person, name: 'Adam Benson')
      FactoryBot.create(:person, name: 'Solo Person')

      expect(described_class.new.duplicate_ids(Person.all)).to contain_exactly(dup1.id, dup2.id)
      expect(described_class.new.duplicate_ids(Person.all)).not_to include(keeper.id)
    end

    it 'respects the given scope' do
      in_scope_keeper = FactoryBot.create(:person, name: 'Scoped Duplicate')
      in_scope_dup = FactoryBot.create(:person, name: 'Scoped Duplicate')
      FactoryBot.create(:person, name: 'Unscoped Duplicate')
      FactoryBot.create(:person, name: 'Unscoped Duplicate')

      scope = Person.where(id: [in_scope_keeper.id, in_scope_dup.id])

      expect(described_class.new.duplicate_ids(scope)).to contain_exactly(in_scope_dup.id)
    end
  end

  describe '#keeper_for' do
    let!(:keeper) { FactoryBot.create(:person, name: 'Adam Benson') }
    let!(:dup) { FactoryBot.create(:person, name: 'Adam Benson') }

    it 'returns the lowest-id same-name person when no block is given' do
      expect(described_class.new.keeper_for(dup, scope: Person.all)).to eq(keeper)
    end

    it 'returns nil when there is no same-name person' do
      solo = FactoryBot.create(:person, name: 'Solo Person')

      expect(described_class.new.keeper_for(solo, scope: Person.all)).to be_nil
    end

    it 'yields each same-name candidate in id order and returns the first the block accepts' do
      other_keeper = FactoryBot.create(:person, name: 'Adam Benson')

      result = described_class.new.keeper_for(dup, scope: Person.all) { |_person, candidate| candidate == other_keeper }

      expect(result).to eq(other_keeper)
    end

    it 'returns nil when the block rejects every candidate' do
      result = described_class.new.keeper_for(dup, scope: Person.all) { |_person, _candidate| false }

      expect(result).to be_nil
    end
  end
end
