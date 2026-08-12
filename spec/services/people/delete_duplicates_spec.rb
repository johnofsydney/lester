require 'rails_helper'

RSpec.describe People::DeleteDuplicates do
  describe '#call' do
    context 'with three people sharing a name' do
      let!(:keeper) { FactoryBot.create(:person, name: 'Adam Benson') }
      let!(:dup1) { FactoryBot.create(:person, name: 'Adam Benson') }
      let!(:dup2) { FactoryBot.create(:person, name: 'Adam Benson') }

      context 'when dry_run is true (default)' do
        it 'does not merge or destroy anyone' do
          expect { described_class.new.call }.not_to change(Person, :count)
          expect(Person.exists?(dup1.id)).to be(true)
          expect(Person.exists?(dup2.id)).to be(true)
        end
      end

      context 'when dry_run is false' do
        it 'folds every duplicate into the lowest-id keeper' do
          expect { described_class.new.call(dry_run: false) }.to change(Person, :count).by(-2)

          expect(Person.exists?(keeper.id)).to be(true)
          expect(Person.exists?(dup1.id)).to be(false)
          expect(Person.exists?(dup2.id)).to be(false)
        end
      end
    end

    context 'with no duplicates' do
      it 'does nothing' do
        FactoryBot.create(:person, name: 'Solo Person')

        expect { described_class.new.call(dry_run: false) }.not_to change(Person, :count)
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
end
