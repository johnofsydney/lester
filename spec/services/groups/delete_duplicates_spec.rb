require 'rails_helper'

RSpec.describe Groups::DeleteDuplicates do
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
end
