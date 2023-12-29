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

  describe '#related_transfers' do
    let!(:alp) { Group.create(name: 'Australian Labor Party') }
    let!(:phon) { Group.create(name: 'One Nation') }
    let!(:coalition) { Group.create(name: 'The Coalition') }
    let!(:awh) { Group.create(name: 'Australian Water Holdings') }
    let!(:obeid_family) { Group.create(name: 'Obeid Family') }

    let!(:latham) { Person.create(name: 'Mark Latham') }
    let!(:hanson) { Person.create(name: 'Pauline Hanson') }
    let!(:sinodinos) { Person.create(name: 'Arthur Sinodinos') }
    let!(:obeid_senior) { Person.create(name: 'Eddie Obeid Senior') }
    let!(:obeid_junior) { Person.create(name: 'Eddie Obeid Junior') }

    let!(:latham_alp_membership) { Membership.create(person: latham, group: alp, start_date: Date.new(1989, 1, 1), end_date: Date.new(2005, 1, 1)) }
    let!(:latham_phon_membership) { Membership.create(person: latham, group: phon, start_date: Date.new(2018, 1, 1), end_date: Date.new(2019, 1, 1)) }
    let!(:hanson_phon_membership) { Membership.create(person: hanson, group: phon, start_date: Date.new(1996, 1, 1)) }
    let!(:sinodinos_coalition_membership) { Membership.create(person: sinodinos, group: coalition, start_date: Date.new(2011, 10, 13), end_date: Date.new(2019, 11, 11)) }
    let!(:sinodinos_awh_membership) { Membership.create(person: sinodinos, group: awh, start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 10, 13)) }
    let!(:obeid_senior_alp_membership) { Membership.create(person: obeid_senior, group: alp, start_date: Date.new(1991, 1, 1), end_date: Date.new(2011, 10, 13)) }
    let!(:obeid_senior_obeid_family_membership) { Membership.create(person: obeid_senior, group: obeid_family, start_date: Date.new(1940, 1, 1)) }
    let!(:obeid_junior_obeid_family_membership) { Membership.create(person: obeid_junior, group: obeid_family, start_date: Date.new(1975, 1, 1)) }
    let!(:obeid_junior_awh_membership) { Membership.create(person: obeid_junior, group: awh, start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 10, 13)) }

    let(:donor) { Group.create(name: 'Donor') }
    let(:recipient) { Group.create(name: 'Recipient') }

    context 'when there is a transfer directly to a Group' do
      before do
        Transfer.create(giver: donor, taker: obeid_family, amount: 100, effective_date: transfer_date)
      end

      context 'when the transfer is before the start date of any external membership' do
        let(:transfer_date) { Date.new(1985, 1, 1) }

        it 'returns just the single transfer' do
          expect(obeid_family.related_transfers.size).to eq(1)
          expect(obeid_family.related_transfers.first.amount).to eq(100)
          expect(obeid_family.related_transfers.first.direction).to eq('incoming')
        end

        it 'doesnt list this transfer with any other group', :aggregate_failures do
          binding.pry
          expect(alp.related_transfers).to be_empty
          expect(phon.related_transfers).to be_empty
          expect(coalition.related_transfers).to be_empty
          expect(awh.related_transfers).to be_empty
        end
      end

      context 'when the transfer is after the end date of any external membership' do
        let(:transfer_date) { Date.new(2020, 1, 1) }

        it 'returns just the single transfer' do
          expect(obeid_family.related_transfers.size).to eq(1)
          expect(obeid_family.related_transfers.first.amount).to eq(100)
          expect(obeid_family.related_transfers.first.direction).to eq('incoming')
        end

        it 'doesnt list this transfer with any other group' do
          expect(alp.related_transfers).to be_empty
          expect(phon.related_transfers).to be_empty
          expect(coalition.related_transfers).to be_empty
          expect(awh.related_transfers).to be_empty
        end
      end

      context 'when the transfer is during the start and end dates of an external membership' do
        let(:transfer_date) { Date.new(2009, 1, 1) }

        it 'does a foo', :aggregate_failures do

          expect(alp.related_transfers).to_not be_empty
          expect(phon.related_transfers).to be_empty
          expect(coalition.related_transfers).to_not be_empty
          expect(awh.related_transfers).to_not be_empty
        end
      end
    end
  end
end