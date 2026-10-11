require 'rails_helper'

RSpec.describe Maintenance::DedupeGroupsTask do
  let!(:keeper) { FactoryBot.create(:group, name: 'Acme Foundation') }
  let!(:dup1) { FactoryBot.create(:group, name: 'Acme Foundation') }
  let!(:dup2) { FactoryBot.create(:group, name: 'Acme Foundation') }
  let!(:unrelated) { FactoryBot.create(:group, name: 'Solo Group') }

  before { allow(Cache::BuildGroupCachedDataJob).to receive(:perform_async) }

  describe '#collection' do
    it 'includes every duplicate except the lowest-id keeper for each name' do
      expect(described_class.collection).to contain_exactly(dup1, dup2)
    end

    it 'excludes groups with a unique name' do
      expect(described_class.collection).not_to include(unrelated)
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      expect(described_class.count).to eq(2)
    end
  end

  describe '#process' do
    context 'when dry_run is true (default)' do
      it 'does not merge or destroy anyone' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        expect { task.process(dup1) }.not_to change(Group, :count)
        expect(Group.exists?(dup1.id)).to be(true)
      end
    end

    context 'when dry_run is false' do
      it 'merges the duplicate into the lowest-id keeper' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(dup1) }.to change(Group, :count).by(-1)
        expect(Group.exists?(keeper.id)).to be(true)
        expect(Group.exists?(dup1.id)).to be(false)
      end

      it 'enqueues a cache refresh job for the keeper' do
        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(dup1)

        expect(Cache::BuildGroupCachedDataJob).to have_received(:perform_async).with(keeper.id)
      end

      it 'is safe to process the same element twice' do
        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(dup1)

        expect { task.process(dup1) }.not_to raise_error
        expect(Group.exists?(keeper.id)).to be(true)
      end

      it 'is safe to process a duplicate whose siblings were already merged by an earlier row' do
        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(dup1)

        expect { task.process(dup2) }.not_to raise_error
        expect(Group.exists?(keeper.id)).to be(true)
        expect(Group.exists?(dup2.id)).to be(false)
      end

      it 'leaves unrelated groups untouched' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(dup1) }.not_to(change { Group.exists?(unrelated.id) })
      end

      it 'leaves a group with no same-name group for manual review' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(unrelated) }.not_to change(Group, :count)
        expect(Group.exists?(unrelated.id)).to be(true)
      end

      it 'leaves a pair with clashing business numbers for manual review instead of raising' do
        keeper.update!(business_number: '11 111 111 111')
        dup1.update!(business_number: '22 222 222 222')

        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(dup1) }.not_to raise_error
        expect(Group.exists?(keeper.id)).to be(true)
        expect(Group.exists?(dup1.id)).to be(true)
      end
    end
  end
end
