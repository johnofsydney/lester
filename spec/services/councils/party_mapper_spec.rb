require 'rails_helper'

RSpec.describe Councils::PartyMapper, type: :service do
  subject(:call_service) { described_class.call(party_label, state: :nsw) }

  before do
    FactoryBot.create(:group, name: Group::NAMES.labor.nsw, type: 'Tag')
    FactoryBot.create(:group, name: Group::NAMES.greens.nsw, type: 'Tag')
    FactoryBot.create(:group, name: Group::NAMES.liberals.nsw, type: 'Tag')
    FactoryBot.create(:group, name: Group::NAMES.nationals.nsw, type: 'Tag')
  end

  context 'when the label matches Labor' do
    let(:party_label) { 'Australian Labor Party (NSW Branch)' }

    it 'returns the NSW Labor tag group' do
      expect(call_service.name).to eq(Group::NAMES.labor.nsw)
    end
  end

  context 'when the label matches the Greens' do
    let(:party_label) { 'The Greens NSW' }

    it 'returns the NSW Greens tag group' do
      expect(call_service.name).to eq(Group::NAMES.greens.nsw)
    end
  end

  context 'when the label matches Liberal' do
    let(:party_label) { 'The Liberal Party Of Australia, New South Wales Division' }

    it 'returns the NSW Liberals tag group' do
      expect(call_service.name).to eq(Group::NAMES.liberals.nsw)
    end
  end

  context 'when the label matches National' do
    let(:party_label) { 'The Nationals' }

    it 'returns the NSW Nationals tag group' do
      expect(call_service.name).to eq(Group::NAMES.nationals.nsw)
    end
  end

  context 'when the label is Independent' do
    let(:party_label) { 'Independent' }

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end

  context 'when the label is a local independents ticket' do
    let(:party_label) { 'Strathfield Independents' }

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end

  context 'when the label is blank' do
    let(:party_label) { '' }

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end

  context 'when the matching party tag group does not exist in the DB' do
    let(:party_label) { 'Australian Labor Party (NSW Branch)' }

    before { Group.where(name: Group::NAMES.labor.nsw).delete_all }

    it 'returns nil rather than raising' do
      expect(call_service).to be_nil
    end
  end
end
