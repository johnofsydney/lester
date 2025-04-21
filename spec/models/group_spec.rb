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
    it 'returns all owning groups and sub groups' do
      expect(group.affiliated_groups).to contain_exactly(owning_group1, owning_group2, sub_group1, sub_group2)
    end
  end

  describe '#transfers' do
    it 'returns all incoming and outgoing transfers' do
      expect(group.transfers.incoming).to contain_exactly(incoming_transfer)
      expect(group.transfers.outgoing).to contain_exactly(outgoing_transfer)
    end
  end

  describe '#other_edge_ends' do
    it 'returns all takers of outgoing transfers and givers of incoming transfers' do
      expect(group.other_edge_ends).to contain_exactly(owning_group2, owning_group1)
    end
  end

  describe '#nodes' do
    it 'returns all people, affiliated groups and other edge ends when include_looser_nodes is true' do
      expect(group.nodes(include_looser_nodes: true)).to contain_exactly(person, owning_group1, owning_group2, sub_group1, sub_group2, owning_group2, owning_group1)
    end

    it 'returns all people and affiliated groups when include_looser_nodes is false' do
      expect(group.nodes(include_looser_nodes: false)).to contain_exactly(person, owning_group1, owning_group2, sub_group1, sub_group2)
    end
  end

  describe '#business_number=' do
    it 'strips non-numeric characters from the business number' do
      group.business_number = '123 456 789'
      group.save
      expect(group.reload.business_number).to eq('123456789')
    end
  end
end