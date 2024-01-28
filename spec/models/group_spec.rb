require 'rails_helper'

RSpec.describe Group, type: :model do
  # let(:group) { Group.create }
  # let(:owning_group1) { Group.create }
  # let(:owning_group2) { Group.create }
  # let(:sub_group1) { Group.create }
  # let(:sub_group2) { Group.create }
  # let(:person) { Person.create }
  # let(:membership) { Membership.create(group: group, person: person) }
  # let(:incoming_transfer) { Transfer.create(giver: owning_group1, taker: group, amount: 100, effective_date: Date.today) }
  # let(:outgoing_transfer) { Transfer.create(giver: group, taker: owning_group2, amount: 50, effective_date: Date.today) }

  # before do
  #   group.owning_groups << owning_group1
  #   group.owning_groups << owning_group2
  #   group.sub_groups << sub_group1
  #   group.sub_groups << sub_group2
  #   group.memberships << membership
  #   group.incoming_transfers << incoming_transfer
  #   group.outgoing_transfers << outgoing_transfer
  # end

  describe '#affiliated_groups', :pending do
    it 'returns all owning groups and sub groups' do
      expect(group.affiliated_groups).to contain_exactly(owning_group1, owning_group2, sub_group1, sub_group2)
    end
  end

  describe '#transfers', :pending do
    it 'returns all incoming and outgoing transfers' do
      expect(group.transfers.incoming).to contain_exactly(incoming_transfer)
      expect(group.transfers.outgoing).to contain_exactly(outgoing_transfer)
    end
  end

  describe '#other_edge_ends', :pending do
    it 'returns all takers of outgoing transfers and givers of incoming transfers' do
      expect(group.other_edge_ends).to contain_exactly(owning_group2, owning_group1)
    end
  end

  describe '#nodes', :pending do
    it 'returns all people, affiliated groups and other edge ends when include_looser_nodes is true' do
      expect(group.nodes(include_looser_nodes: true)).to contain_exactly(person, owning_group1, owning_group2, sub_group1, sub_group2, owning_group2, owning_group1)
    end

    it 'returns all people and affiliated groups when include_looser_nodes is false' do
      expect(group.nodes(include_looser_nodes: false)).to contain_exactly(person, owning_group1, owning_group2, sub_group1, sub_group2)
    end
  end
end