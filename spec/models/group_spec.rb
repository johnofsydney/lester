require 'rails_helper'

RSpec.describe Group do
  let(:group) { described_class.create }

  it { should have_many(:memberships) }
  it { should have_many(:people) }
  it { should have_many(:groups) }
  it { should have_many(:outgoing_transfers) }
  it { should have_many(:incoming_transfers) }

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

    it 'does not allow two groups with the same business number' do
      group1 = described_class.create(business_number: '123456789')
      group2 = described_class.new(business_number: '123456789')
      expect(group2).not_to be_valid
    end

    it 'does not allow two groups with the same business number even if there are spaces' do
      group1 = described_class.create(business_number: '123 45 6789')
      group2 = described_class.new(business_number: '12 345 67 89')
      expect(group2).not_to be_valid
    end

    it 'does not allow two groups with the same business number even if there are dashes' do
      group1 = described_class.create(business_number: '123-45-6789')
      group2 = described_class.new(business_number: '12-345-67-89')
      expect(group2).not_to be_valid
    end

    it 'allows two groups with nil business number' do
      group1 = described_class.create(name: 'foo')
      group2 = described_class.create(name: 'bar')
      expect(group2).to be_valid
    end
  end

  describe '#affiliated_groups' do

    let(:owning_group1) { described_class.create(name: 'Owning Group 1') }
    let(:owning_group2) { described_class.create(name: 'Owning Group 2') }
    let(:sub_group1) { described_class.create(name: 'Sub Group 1') }
    let(:sub_group2) { described_class.create(name: 'Sub Group 2') }

    before do
      Membership.create(group: owning_group1, member: group)
      Membership.create(group: owning_group2, member: group)
      Membership.create(group: group, member: sub_group1)
      Membership.create(group: group, member: sub_group2)
    end

    it 'returns all owning groups and sub groups' do
      expect(group.affiliated_groups).to contain_exactly(owning_group1, owning_group2, sub_group1, sub_group2)
    end
  end

  describe '#transfers' do
    let(:giving_group) { described_class.create(name: 'Giving Group') }
    let(:receiver_group) { described_class.create(name: 'Receiver Group') }
    let!(:incoming_transfer) { Transfer.create(taker: group, giver: giving_group, amount: 123, effective_date: Date.new(2025,12,25)) }
    let!(:outgoing_transfer) { Transfer.create(taker: receiver_group, giver: group, amount: 123, effective_date: Date.new(2025,12,25)) }

    it 'returns all incoming and outgoing transfers' do
      expect(group.incoming_transfers).to contain_exactly(incoming_transfer)
      expect(group.outgoing_transfers).to contain_exactly(outgoing_transfer)
    end
  end

  # describe '#other_edge_ends' do
  #   it 'returns all takers of outgoing transfers and givers of incoming transfers' do
  #     expect(group.other_edge_ends).to contain_exactly(owning_group2, owning_group1)
  #   end
  # end

  describe '#nodes' do
    let(:person) { Person.create(name: 'Test Person') }
    let(:owning_group1) { described_class.create(name: 'Owning Group 1') }
    let(:owning_group2) { described_class.create(name: 'Owning Group 2') }
    let(:sub_group1) { described_class.create(name: 'Sub Group 1') }
    let(:sub_group2) { described_class.create(name: 'Sub Group 2') }

    before do
      Membership.create(group: owning_group1, member: group)
      Membership.create(group: owning_group2, member: group)
      Membership.create(group: group, member: sub_group1)
      Membership.create(group: group, member: sub_group2)
      Membership.create(group: group, member: person)
    end

    it 'returns all people and affiliated groups (child groups and parent groups)' do
      expect(group.nodes).to contain_exactly(person, owning_group1, owning_group2, sub_group1, sub_group2)
    end
  end

  describe '#business_number=' do
    it 'strips non-numeric characters from the business number' do
      group.business_number = '123 456 789'
      group.save
      expect(group.reload.business_number).to eq('123456789')
    end
  end

  describe 'node methods' do
    let(:group) { Group.create(name: 'Test Group') }

    before do
      # Transfers where the group is the giver
      Transfer.create(giver: group, taker: Person.create(name: 'Person A'), amount: 100, effective_date: Date.new(2024,1,1))
      Transfer.create(giver: group, taker: Person.create(name: 'Person B'), amount: 200, effective_date: Date.new(2024,2,1))
      Transfer.create(giver: group, taker: Group.create(name: 'Group C'), amount: 300, effective_date: Date.new(2024,3,1))
      Transfer.create(giver: group, taker: Group.create(name: 'Group D'), amount: 400, effective_date: Date.new(2024,4,1))
      Transfer.create(giver: group, taker: Person.create(name: 'Person E'), amount: 500, effective_date: Date.new(2024,5,1))
      Transfer.create(giver: group, taker: Person.create(name: 'Person F'), amount: 600, effective_date: Date.new(2024,6,1))

      # Transfers where the group is the taker
      Transfer.create(taker: group, giver: Person.create(name: 'Person G'), amount: 150, effective_date: Date.new(2024,1,15))
      Transfer.create(taker: group, giver: Person.create(name: 'Person H'), amount: 250, effective_date: Date.new(2024,2,15))
      Transfer.create(taker: group, giver: Group.create(name: 'Group I'), amount: 350, effective_date: Date.new(2024,3,15))
      Transfer.create(taker: group, giver: Group.create(name: 'Group J'), amount: 450, effective_date: Date.new(2024,4,15))
      Transfer.create(taker: group, giver: Person.create(name: 'Person K'), amount: 550, effective_date: Date.new(2024,5,15))
      Transfer.create(taker: group, giver: Person.create(name: 'Person L'), amount: 650, effective_date: Date.new(2024,6,15))
    end

    describe '#all_the_groups' do
      it 'returns a hash with sums of amounts given and taken grouped by taker and giver' do
        expect(group.all_the_groups).to eq(
          {
            as_giver: [
              ['Person A', 100.0],
              ['Person B', 200.0],
              ['Group C', 300.0],
              ['Group D', 400.0],
              ['Person E', 500.0],
              ['Person F', 600.0]
            ],
            as_taker: [
              ['Person G', 150.0],
              ['Person H', 250.0],
              ['Group I', 350.0],
              ['Group J', 450.0],
              ['Person K', 550.0],
              ['Person L', 650.0]
            ]
          }
        )
      end
    end
  end
end