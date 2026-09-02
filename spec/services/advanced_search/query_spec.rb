require 'rails_helper'

RSpec.describe AdvancedSearch::Query, type: :service do
  describe '#call' do
    context 'with no filters' do
      it 'returns all people, ordered by name, when entity_type is Person' do
        create(:person, name: 'Zoe Adams')
        create(:person, name: 'Amy Zeller')

        results = described_class.new(entity_type: 'Person').call

        expect(results.map(&:name)).to eq(['amy zeller', 'zoe adams'])
      end

      it 'returns all groups, ordered by name, when entity_type is Group' do
        create(:group, name: 'Zeta Group')
        create(:group, name: 'Alpha Group')

        results = described_class.new(entity_type: 'Group').call

        expect(results.map(&:name)).to eq(['alpha group', 'zeta group'])
      end

      it 'does not include people when entity_type is Group' do
        create(:person, name: 'Should Not Appear')
        create(:group, name: 'Should Appear')

        results = described_class.new(entity_type: 'Group').call

        expect(results.map(&:name)).to eq(['should appear'])
      end
    end

    context 'with a single facet filter' do
      it 'returns only people who belong to the given group' do
        lobbyist_tag = create(:group, name: 'Lobbyist')
        member = create(:person, name: 'In Group')
        non_member = create(:person, name: 'Not In Group')
        create(:membership, member: member, group: lobbyist_tag)

        filters = [{ facet_value_id: lobbyist_tag.id }]
        results = described_class.new(entity_type: 'Person', filters: filters).call

        expect(results.map(&:name)).to contain_exactly('in group')
        expect(results.map(&:name)).not_to include(non_member.name)
      end

      it 'returns only groups who belong to the given group' do
        parent = create(:group, name: 'Parent Group')
        member = create(:group, name: 'Member Group')
        non_member = create(:group, name: 'Non Member Group')
        create(:membership, member: member, group: parent)

        filters = [{ facet_value_id: parent.id }]
        results = described_class.new(entity_type: 'Group', filters: filters).call

        expect(results.map(&:name)).to contain_exactly('member group')
        expect(results.map(&:name)).not_to include(non_member.name)
      end

      it 'ignores a filter with a blank facet_value_id' do
        create(:person, name: 'Everyone')

        filters = [{ facet_value_id: nil }]
        results = described_class.new(entity_type: 'Person', filters: filters).call

        expect(results.map(&:name)).to eq(['everyone'])
      end
    end

    context 'with multiple facet filters' do
      it 'ANDs by default, requiring membership in every group' do
        lobbyist = create(:group, name: 'Lobbyist')
        nsw_parliament = create(:group, name: 'NSW Parliament')

        both = create(:person, name: 'Both')
        create(:membership, member: both, group: lobbyist)
        create(:membership, member: both, group: nsw_parliament)

        only_lobbyist = create(:person, name: 'Only Lobbyist')
        create(:membership, member: only_lobbyist, group: lobbyist)

        filters = [
          { joiner: 'AND', facet_value_id: lobbyist.id },
          { joiner: 'AND', facet_value_id: nsw_parliament.id }
        ]
        results = described_class.new(entity_type: 'Person', filters: filters).call

        expect(results.map(&:name)).to contain_exactly('both')
      end

      it 'ORs when a filter row specifies OR, folding left-to-right' do
        lobbyist = create(:group, name: 'Lobbyist')
        charity = create(:group, name: 'Charity')

        in_lobbyist = create(:person, name: 'In Lobbyist')
        create(:membership, member: in_lobbyist, group: lobbyist)

        in_charity = create(:person, name: 'In Charity')
        create(:membership, member: in_charity, group: charity)

        in_neither = create(:person, name: 'In Neither')

        filters = [
          { joiner: 'AND', facet_value_id: lobbyist.id },
          { joiner: 'OR', facet_value_id: charity.id }
        ]
        results = described_class.new(entity_type: 'Person', filters: filters).call

        expect(results.map(&:name)).to contain_exactly('in lobbyist', 'in charity')
        expect(results.map(&:name)).not_to include(in_neither.name)
      end

      it 'folds strictly left-to-right rather than applying AND/OR precedence' do
        lobbyist = create(:group, name: 'Lobbyist')
        charity = create(:group, name: 'Charity')
        nsw_parliament = create(:group, name: 'NSW Parliament')

        # (lobbyist OR charity) AND nsw_parliament - not lobbyist OR (charity AND nsw_parliament)
        matches_fold = create(:person, name: 'Matches Fold')
        create(:membership, member: matches_fold, group: lobbyist)
        create(:membership, member: matches_fold, group: nsw_parliament)

        only_lobbyist = create(:person, name: 'Only Lobbyist')
        create(:membership, member: only_lobbyist, group: lobbyist)

        filters = [
          { joiner: 'AND', facet_value_id: lobbyist.id },
          { joiner: 'OR', facet_value_id: charity.id },
          { joiner: 'AND', facet_value_id: nsw_parliament.id }
        ]
        results = described_class.new(entity_type: 'Person', filters: filters).call

        expect(results.map(&:name)).to contain_exactly('matches fold')
      end
    end
  end
end
