require 'rails_helper'

RSpec.describe Maintenance::CleanupOrphanedMembershipsTask do
  let!(:parent) { create(:group) }
  let!(:child) { create(:group) }
  let!(:healthy_membership) { create(:membership, member: child, group: parent) }

  let!(:orphaned_group) { create(:group) }
  let!(:orphaned_group_membership) { create(:membership, member: orphaned_group, group: parent) }

  let!(:orphaned_person) { create(:person) }
  let!(:orphaned_person_membership) { create(:membership, member: orphaned_person, group: parent) }

  before do
    # .delete bypasses dependent: :destroy, simulating a pre-existing orphaned row from before
    # the cascade fix was in place.
    orphaned_group.delete
    orphaned_person.delete
  end

  describe '#collection' do
    it 'includes only Memberships whose polymorphic member no longer exists' do
      expect(described_class.collection).to contain_exactly(orphaned_group_membership, orphaned_person_membership)
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      expect(described_class.count).to eq(2)
    end
  end

  describe '#process' do
    context 'when dry_run is true (default)' do
      it 'does not delete the Membership' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        expect { task.process(orphaned_group_membership) }.not_to change(Membership, :count)
        expect(Membership.exists?(orphaned_group_membership.id)).to be(true)
      end
    end

    context 'when dry_run is false' do
      let(:task) { described_class.new.tap { |t| t.dry_run = false } }

      it 'deletes the orphaned Membership' do
        expect { task.process(orphaned_group_membership) }.to change(Membership, :count).by(-1)
        expect(Membership.exists?(orphaned_group_membership.id)).to be(false)
      end

      it 'deletes any Positions attached to the orphaned Membership' do
        position = orphaned_group_membership.positions.create!(title: 'Member')

        task.process(orphaned_group_membership)

        expect(Position.exists?(position.id)).to be(false)
      end

      it 'leaves healthy Memberships untouched' do
        expect { task.process(orphaned_group_membership) }.not_to(change { Membership.exists?(healthy_membership.id) })
      end
    end
  end
end
