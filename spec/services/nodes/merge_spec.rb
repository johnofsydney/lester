require 'rails_helper'

RSpec.describe Nodes::Merge, type: :service do
  describe '.call' do
    subject(:merge) { described_class.call(receiver_node:, argument_node:) }

    let!(:group_a) { Group.create!(name: 'Group A') }
    let(:receiver_node) { group_a }
    let(:argument_node) { group_b }
    let!(:group_b) { Group.create!(name: 'Group B') }
    let!(:person_a)  { Person.create!(name: 'Alice') }
    let!(:person_b)  { Person.create!(name: 'Bob') }

    it 'raises when merging node into itself' do
      expect {described_class.call(receiver_node: group_a, argument_node: group_a)}.to raise_error('Cannot merge node into itself')
    end

    it 'raises when merging different types of node' do
      expect {described_class.call(receiver_node: group_a, argument_node: person_a)}.to raise_error('Cannot merge different types of node')
    end

    it 'clears the cache and calls refresh job on receiver_node' do
      allow(BuildGroupCachedDataJob).to receive(:perform_async)
      group_a.update!(cached_data: { some: 'data' })

      merge

      expect(group_a.cached_data).to eq({})
      expect(BuildGroupCachedDataJob).to have_received(:perform_async).with(group_a.id)
    end

    context 'when there are no transfers or memberships' do
      it 'performs merge without errors' do
        result = merge
        expect(result).to eq(receiver_node)
        expect(Group).not_to exist(group_b.id)
      end
    end

    context 'when there are transfers' do
      let!(:transfer1) { Transfer.create!(giver: group_a, taker: person_a, amount: 100, effective_date: Time.zone.today) }
      let!(:individual_transaction1) { IndividualTransaction.create!(transfer: transfer1, amount: 100, effective_date: Time.zone.today) }
      let!(:transfer2) { Transfer.create!(giver: group_b, taker: person_b, amount: 200, effective_date: 1.year.ago) }
      let!(:individual_transaction2) { IndividualTransaction.create!(transfer: transfer2, amount: 200, effective_date: 1.year.ago) }

      let(:transfer3) { Transfer.create!(giver: person_a, taker: group_a, amount: 10, effective_date: Time.zone.today) }
      let(:individual_transaction3) { IndividualTransaction.create!(transfer: transfer3, amount: 10, effective_date: Time.zone.today) }
      let(:transfer4) { Transfer.create!(giver: person_b, taker: group_a, amount: 20, effective_date: 1.year.ago) }
      let(:individual_transaction4) { IndividualTransaction.create!(transfer: transfer4, amount: 20, effective_date: 1.year.ago) }

      it 'moves transfers to receiver_node and merges equivalent transfers' do
        merge
        group_a.reload
        # group_b.reload # cannot reload - it has been destroyed
        transfer1.reload
        transfer2.reload
        transfer3.reload
        transfer4.reload
        individual_transaction1.reload
        individual_transaction2.reload
        individual_transaction3.reload
        individual_transaction4.reload

        expect(Transfer.where(giver: group_b).count).to eq(0)
        expect(Transfer.where(giver: group_a).count).to eq(2)
        expect(group_a.outgoing_transfers.sum(:amount)).to eq(300)

        expect(individual_transaction1.transfer_id).to eq(transfer1.id)
        expect(individual_transaction2.transfer_id).to eq(transfer2.id)

        expect(transfer1.giver_id).to eq(group_a.id)
        expect(transfer2.giver_id).to eq(group_a.id)

        expect(Transfer.where(taker: group_b).count).to eq(0)
        expect(Transfer.where(taker: group_a).count).to eq(2)
        expect(group_a.incoming_transfers.sum(:amount)).to eq(30)

        expect(individual_transaction3.transfer_id).to eq(transfer3.id)
        expect(individual_transaction4.transfer_id).to eq(transfer4.id)

        expect(transfer3.taker_id).to eq(group_a.id)
        expect(transfer4.taker_id).to eq(group_a.id)
      end
    end

    context 'when there are transfers which are equivalent and have to be merged' do
      let!(:transfer_a1) { Transfer.create!(giver: group_a, taker: person_a, amount: 150, effective_date: Time.zone.today) }
      let!(:individual_transaction_a1) { IndividualTransaction.create!(transfer: transfer_a1, amount: 150, effective_date: Time.zone.today) }
      let!(:transfer_b1) { Transfer.create!(giver: group_b, taker: person_a, amount: 250, effective_date: Time.zone.today) }
      let!(:individual_transaction_b1) { IndividualTransaction.create!(transfer: transfer_b1, amount: 250, effective_date: Time.zone.today) }

      let!(:transfer_c1) { Transfer.create!(giver: person_a, taker: group_a, amount: 50, effective_date: Time.zone.today) }
      let!(:individual_transaction_c1) { IndividualTransaction.create!(transfer: transfer_c1, amount: 50, effective_date: Time.zone.today) }
      let!(:transfer_d1) { Transfer.create!(giver: person_a, taker: group_b, amount: 75, effective_date: Time.zone.today) }
      let!(:individual_transaction_d1) { IndividualTransaction.create!(transfer: transfer_d1, amount: 75, effective_date: Time.zone.today) }

      it 'merges equivalent transfers and moves individual transactions' do
        merge
        group_a.reload
        # group_b.reload, transfer_b1 # cannot reload - it has been destroyed
        transfer_a1.reload
        transfer_c1.reload
        individual_transaction_a1.reload
        individual_transaction_b1.reload
        individual_transaction_c1.reload
        individual_transaction_d1.reload

        expect(Transfer.where(giver: group_b).count).to eq(0)
        expect(Transfer.where(giver: group_a).count).to eq(1)
        expect(group_a.outgoing_transfers.sum(:amount)).to eq(400)
        expect(individual_transaction_a1.transfer_id).to eq(transfer_a1.id)
        expect(individual_transaction_b1.transfer_id).to eq(transfer_a1.id)
        expect(transfer_a1.amount).to eq(400)

        expect(Transfer.where(taker: group_b).count).to eq(0)
        expect(Transfer.where(taker: group_a).count).to eq(1)
        expect(group_a.incoming_transfers.sum(:amount)).to eq(125)
        expect(individual_transaction_c1.transfer_id).to eq(transfer_c1.id)
        expect(individual_transaction_d1.transfer_id).to eq(transfer_c1.id)
        expect(transfer_c1.amount).to eq(125)
      end
    end

    context 'when there are memberships where the entities are the owning groups' do
      before do
        Membership.create!(group: group_a, member: person_a)
        Membership.create!(group: group_b, member: person_b)
        Membership.create!(group: group_b, member: person_a)
      end

      it 'moves memberships to receiver_node and removes duplicates' do
        merge
        group_a.reload
        # group_b.reload # cannot reload - it has been destroyed
        expect(Membership.where(group: group_b).count).to eq(0)
        expect(Membership.where(group: group_a).count).to eq(2)
        expect(Membership).to exist(group: group_a, member: person_a)
        expect(Membership).to exist(group: group_a, member: person_b)
      end
    end

    context 'when there are memberships where the entities are the members' do
      let!(:parent_group1) { Group.create!(name: 'Parent Group 1') }
      let!(:parent_group2) { Group.create!(name: 'Parent Group 2') }

      before do
        Membership.create!(group: parent_group1, member: group_a)
        Membership.create!(group: parent_group2, member: group_b)
        Membership.create!(group: parent_group1, member: group_b)
      end

      it 'moves memberships to receiver_node and removes duplicates' do
        merge
        group_a.reload
        parent_group1.reload
        parent_group2.reload
        # group_b.reload # cannot reload - it has been destroyed
        expect(Membership.where(member: group_b).count).to eq(0)
        expect(Membership.where(member: group_a).count).to eq(2)
        expect(Membership).to exist(group: parent_group1, member: group_a)
        expect(Membership).to exist(group: parent_group2, member: group_a)
      end
    end
  end
end
