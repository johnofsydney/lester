require 'rails_helper'

RSpec.describe Groups::AddToTag do
  describe '#call' do
    let(:tag) { FactoryBot.create(:group, name: 'Some Tag') }
    let(:group1) { FactoryBot.create(:group) }
    let(:group2) { FactoryBot.create(:group) }

    it 'creates a membership linking each group to the tag' do
      described_class.call(group_ids: [group1.id, group2.id], tag: tag)

      expect(tag.memberships.where(member: group1, member_type: 'Group')).to exist
      expect(tag.memberships.where(member: group2, member_type: 'Group')).to exist
    end

    it 'does not affect groups outside the given ids' do
      other_group = FactoryBot.create(:group)

      described_class.call(group_ids: [group1.id], tag: tag)

      expect(tag.memberships.where(member: other_group, member_type: 'Group')).not_to exist
    end
  end
end
