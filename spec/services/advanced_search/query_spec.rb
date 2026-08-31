require 'rails_helper'

RSpec.describe AdvancedSearch::Query do
  describe '#searchable?' do
    it 'is false with no filters and no name' do
      expect(described_class.new(entity_type: 'Person').searchable?).to be false
    end

    it 'is true once a filter has a facet value' do
      tag = FactoryBot.create(:tag)
      query = described_class.new(entity_type: 'Person', filters: [{ facet_type: 'Category', facet_value_id: tag.id }])

      expect(query.searchable?).to be true
    end

    it 'is true with just a name, even with no filters' do
      expect(described_class.new(entity_type: 'Person', name: 'kevin').searchable?).to be true
    end
  end

  describe '#call' do
    let(:lobbyists) { FactoryBot.create(:tag, name: 'Lobbyists') }
    let(:charities) { FactoryBot.create(:tag, name: 'Charities') }
    let(:nsw_parliament) { FactoryBot.create(:group, name: 'NSW Parliament') }

    it 'defaults to Person for an unrecognised entity_type' do
      expect(described_class.new(entity_type: 'Transfer').entity_type).to eq('Person')
    end

    it 'drops filter rows with a blank facet value' do
      query = described_class.new(entity_type: 'Person', filters: [{ facet_type: 'Category', facet_value_id: '' }])

      expect(query.filters).to be_empty
    end

    it 'returns everyone when there are no filters and no name' do
      alice = FactoryBot.create(:person, name: 'alice')

      results = described_class.new(entity_type: 'Person').call

      expect(results).to include(alice)
    end

    it 'filters people down to members of a single category' do
      alice = FactoryBot.create(:person, name: 'alice')
      bob = FactoryBot.create(:person, name: 'bob')
      FactoryBot.create(:membership, member: alice, group: lobbyists)

      results = described_class.new(
        entity_type: 'Person',
        filters: [{ facet_type: 'Category', facet_value_id: lobbyists.id }]
      ).call

      expect(results).to contain_exactly(alice)
      expect(results).not_to include(bob)
    end

    it 'combines two filters with AND' do
      alice = FactoryBot.create(:person, name: 'alice')
      bob = FactoryBot.create(:person, name: 'bob')
      FactoryBot.create(:membership, member: alice, group: lobbyists)
      FactoryBot.create(:membership, member: alice, group: nsw_parliament)
      FactoryBot.create(:membership, member: bob, group: lobbyists)

      results = described_class.new(
        entity_type: 'Person',
        filters: [
          { facet_type: 'Category', facet_value_id: lobbyists.id },
          { joiner: 'AND', facet_type: 'Group', facet_value_id: nsw_parliament.id }
        ]
      ).call

      expect(results).to contain_exactly(alice)
    end

    it 'combines two filters with OR' do
      alice = FactoryBot.create(:person, name: 'alice')
      bob = FactoryBot.create(:person, name: 'bob')
      carol = FactoryBot.create(:person, name: 'carol')
      FactoryBot.create(:membership, member: alice, group: lobbyists)
      FactoryBot.create(:membership, member: bob, group: charities)

      results = described_class.new(
        entity_type: 'Person',
        filters: [
          { facet_type: 'Category', facet_value_id: lobbyists.id },
          { joiner: 'OR', facet_type: 'Category', facet_value_id: charities.id }
        ]
      ).call

      expect(results).to contain_exactly(alice, bob)
      expect(results).not_to include(carol)
    end

    it 'folds mixed AND/OR left-to-right rather than by SQL AND-before-OR precedence' do
      # (lobbyists OR charities) AND nsw_parliament -- only Alice is in both an OR term and the AND term
      alice = FactoryBot.create(:person, name: 'alice')
      bob = FactoryBot.create(:person, name: 'bob')
      FactoryBot.create(:membership, member: alice, group: lobbyists)
      FactoryBot.create(:membership, member: alice, group: nsw_parliament)
      FactoryBot.create(:membership, member: bob, group: lobbyists) # matches the OR term but not the AND term

      results = described_class.new(
        entity_type: 'Person',
        filters: [
          { facet_type: 'Category', facet_value_id: lobbyists.id },
          { joiner: 'OR', facet_type: 'Category', facet_value_id: charities.id },
          { joiner: 'AND', facet_type: 'Group', facet_value_id: nsw_parliament.id }
        ]
      ).call

      expect(results).to contain_exactly(alice)
    end

    it 'narrows filtered results further by name' do
      alice = FactoryBot.create(:person, name: 'alice smith')
      alison = FactoryBot.create(:person, name: 'alison jones')
      FactoryBot.create(:membership, member: alice, group: lobbyists)
      FactoryBot.create(:membership, member: alison, group: lobbyists)

      results = described_class.new(
        entity_type: 'Person',
        filters: [{ facet_type: 'Category', facet_value_id: lobbyists.id }],
        name: 'smith'
      ).call

      expect(results).to contain_exactly(alice)
    end

    it 'searches Groups when entity_type is Group' do
      member_group = FactoryBot.create(:group, name: 'client of a lobbyist')
      FactoryBot.create(:membership, member: member_group, group: lobbyists)

      results = described_class.new(
        entity_type: 'Group',
        filters: [{ facet_type: 'Category', facet_value_id: lobbyists.id }]
      ).call

      expect(results).to contain_exactly(member_group)
    end
  end
end
