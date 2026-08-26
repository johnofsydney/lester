require 'rails_helper'

RSpec.describe Councils::PartyMapper, type: :service do
  subject(:call_service) { described_class.call(party_label, state: :nsw) }

  before do
    # Real party Groups are plain Groups (type: nil), not Tags -- see
    # docs/adr/0011-tag-type-is-for-category-labels-not-organizations.md.
    FactoryBot.create(:group, name: Group::NAMES.labor.nsw)
    FactoryBot.create(:group, name: Group::NAMES.greens.nsw)
    FactoryBot.create(:group, name: Group::NAMES.liberals.nsw)
    FactoryBot.create(:group, name: Group::NAMES.nationals.nsw)
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

  context 'when the label is the Liberal Democratic Party (not a Group::NAMES family)' do
    let(:party_label) { 'Liberal Democratic Party' }

    before { FactoryBot.create(:group, name: 'Liberal Democratic Party') }

    it 'returns the Liberal Democratic Party group, not the NSW Liberals group' do
      expect(call_service.name).to eq('liberal democratic party')
    end
  end

  context 'when the label is a joint ticket, e.g. "LIBERAL / THE NATIONALS"' do
    let(:party_label) { 'LIBERAL / THE NATIONALS' }

    it 'resolves to the first-named party' do
      expect(call_service.name).to eq(Group::NAMES.liberals.nsw)
    end
  end

  context 'when the label is a joint ticket with National named first' do
    let(:party_label) { 'THE NATIONALS / LIBERAL' }

    it 'resolves to the first-named party' do
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

  describe '.resolved_name' do
    it 'returns the canonical name even when no matching Group exists in the DB' do
      Group.where(name: Group::NAMES.labor.nsw).delete_all

      expect(described_class.resolved_name('Australian Labor Party (NSW Branch)', state: :nsw)).to eq(Group::NAMES.labor.nsw)
    end

    it 'returns nil for an independent' do
      expect(described_class.resolved_name('Independent', state: :nsw)).to be_nil
    end
  end
end
