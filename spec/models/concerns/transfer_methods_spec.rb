require 'rails_helper'

RSpec.describe TransferMethods do
  describe '#tag_incoming_transfers' do
    it 'returns Transfer.none when the group is not a tag' do
      group = create(:group)

      expect(group.tag_incoming_transfers).to eq(Transfer.none)
    end

    it 'includes transfers taken by a member group of the tag' do
      tag = Tag.create!(name: 'charities')
      member_group = create(:group)
      giver = create(:group)
      create(:membership, member: member_group, group: tag)
      transfer = Transfer.create!(taker: member_group, giver: giver, amount: 100, effective_date: Date.new(2025, 1, 1))

      expect(tag.tag_incoming_transfers).to contain_exactly(transfer)
    end

    it 'includes transfers taken by a member person of the tag' do
      tag = Tag.create!(name: 'lobbyists')
      member_person = create(:person)
      giver = create(:group)
      create(:membership, member: member_person, group: tag)
      transfer = Transfer.create!(taker: member_person, giver: giver, amount: 50, effective_date: Date.new(2025, 1, 1))

      expect(tag.tag_incoming_transfers).to contain_exactly(transfer)
    end

    it 'excludes transfers between two member groups of the same tag' do
      tag = Tag.create!(name: 'charities')
      member_group1 = create(:group)
      member_group2 = create(:group)
      create(:membership, member: member_group1, group: tag)
      create(:membership, member: member_group2, group: tag)
      Transfer.create!(taker: member_group1, giver: member_group2, amount: 100, effective_date: Date.new(2025, 1, 1))

      expect(tag.tag_incoming_transfers).to be_empty
    end
  end

  describe '#tag_outgoing_transfers' do
    it 'returns Transfer.none when the group is not a tag' do
      group = create(:group)

      expect(group.tag_outgoing_transfers).to eq(Transfer.none)
    end

    it 'includes transfers given by a member group of the tag' do
      tag = Tag.create!(name: 'charities')
      member_group = create(:group)
      taker = create(:group)
      create(:membership, member: member_group, group: tag)
      transfer = Transfer.create!(giver: member_group, taker: taker, amount: 100, effective_date: Date.new(2025, 1, 1))

      expect(tag.tag_outgoing_transfers).to contain_exactly(transfer)
    end

    it 'excludes transfers between two member groups of the same tag' do
      tag = Tag.create!(name: 'charities')
      member_group1 = create(:group)
      member_group2 = create(:group)
      create(:membership, member: member_group1, group: tag)
      create(:membership, member: member_group2, group: tag)
      Transfer.create!(giver: member_group1, taker: member_group2, amount: 100, effective_date: Date.new(2025, 1, 1))

      expect(tag.tag_outgoing_transfers).to be_empty
    end
  end
end
