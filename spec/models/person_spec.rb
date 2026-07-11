require 'rails_helper'

RSpec.describe Person do
  describe 'scopes' do
    let!(:charities_group) { Group.create(name: 'Charities') }
    let!(:charity1) { Group.create(name: 'Charity 1') }
    let!(:charity2) { Group.create(name: 'Charity 2') }
    let!(:other_group) { Group.create(name: 'Other Group') }
    let!(:person1) { Person.create(name: 'Person 1') } # only in a charity (charity1)
    let!(:person2) { Person.create(name: 'Person 2') } # in charity 2 and other_group
    let!(:person3) { Person.create(name: 'Person 3') } # in other_group but not in any charity
    let!(:person4) { Person.create(name: 'Person 4') } # in no groups

    before do
      Membership.create(group: charities_group, member: charity1)
      Membership.create(group: charities_group, member: charity2)

      Membership.create(group: charity1, member: person1)

      Membership.create(group: charity2, member: person2)

      Membership.create(group: other_group, member: person2)
      Membership.create(group: other_group, member: person3)

      allow(Group).to receive(:charities_tag).and_return(charities_group)
    end

    describe '.in_charities_subgroups' do
      it 'returns people who are in groups that are subgroups of charities' do
        expect(Person.in_charities_subgroups).to include(person1, person2)
      end

      it 'does not return people who are not in any charity subgroups' do
        expect(Person.in_charities_subgroups).not_to include(person3, person4)
      end
    end

    describe '.only_in_charities' do
      it 'returns people who are only in groups that are subgroups of charities' do
        expect(Person.only_in_charities).to include(person1)
      end

      it 'does not return people who are in any non-charity groups' do
        expect(Person.only_in_charities).not_to include(person2, person3, person4)
      end

      it 'returns an active record relation' do
        expect(Person.only_in_charities).to be_a(ActiveRecord::Relation)
      end
    end
  end

  describe '.only_parliamentary_connections' do
    let(:greens_category) { Tag.create!(name: 'The Greens') }
    let(:alp_category)    { Tag.create!(name: 'Australian Labor Party') }

    let!(:federal_parliament) { Group.create!(name: 'Australian Federal Parliament') }
    let!(:nsw_parliament) { Group.create!(name: 'NSW Parliament') }
    let!(:greens_party_federal) { Group.create!(name: 'The Greens (Federal)') }
    let!(:alp_party_federal) { Group.create!(name: 'ALP (Federal)') }
    let!(:alp_party_nsw) { Group.create!(name: 'ALP (NSW)') }
    let!(:lobbying_group) { Group.create!(name: 'Lobbying Firm') }
    let!(:charity_group) { Group.create!(name: 'Charity Group') }

    let!(:zali_federal_parliament_only) { Person.create!(name: 'Zali') } # independent fed
    let!(:alice_nsw_parliament_only) { Person.create!(name: 'Alice Chamber') } # independent nsw
    let!(:john_party_only) { Person.create!(name: 'John Party') } # only party tag
    let!(:lee_federal_parliament_and_party) { Person.create!(name: 'Lee Both') } # chamber and party tag
    let!(:bruce_federal_and_nsw_parliament_and_party) { Person.create!(name: 'Bruce Both') }

    # rubocop:disable RSpec/LetSetup
    let!(:dave_no_memberships) { Person.create!(name: 'Dave None') }
    let!(:morris_nsw_parliament_and_lobbying) { Person.create!(name: 'Eve Mixed') } # Lobbyist, ex NSW parliamentarian
    let!(:frank_lobby) { Person.create!(name: 'Frank Other') } # Lobbyist, no parliamentary connections
    # rubocop:enable RSpec/LetSetup

    before do
      # Add all of the major parties into a tag group (category) for the purposes of this test
      Membership.create!(group: greens_category, member: greens_party_federal)
      Membership.create!(group: alp_category, member: alp_party_federal)
      Membership.create!(group: alp_category, member: alp_party_nsw)

      # Add the people to their respective groups, person by person
      # Independents
      Membership.create!(member: zali_federal_parliament_only, group: federal_parliament)

      Membership.create!(member: alice_nsw_parliament_only, group: nsw_parliament)

      # Memebers of both a chamber and a party, but not any other groups
      Membership.create!(member: lee_federal_parliament_and_party, group: federal_parliament)
      Membership.create!(member: lee_federal_parliament_and_party, group: greens_party_federal)

      Membership.create!(member: bruce_federal_and_nsw_parliament_and_party, group: federal_parliament)
      Membership.create!(member: bruce_federal_and_nsw_parliament_and_party, group: nsw_parliament)
      Membership.create!(member: bruce_federal_and_nsw_parliament_and_party, group: alp_party_federal)
      Membership.create!(member: bruce_federal_and_nsw_parliament_and_party, group: alp_party_nsw)

      # Members of a chamber and a non-parliamentary group
      Membership.create!(member: morris_nsw_parliament_and_lobbying, group: nsw_parliament)
      Membership.create!(member: morris_nsw_parliament_and_lobbying, group: lobbying_group)

      # Members of a non-parliamentary group only
      Membership.create!(member: frank_lobby, group: lobbying_group)
      Membership.create!(member: frank_lobby, group: charity_group)

      # Members of a party only
      Membership.create!(member: john_party_only, group: greens_party_federal)
    end

    # The scope should include people who are members of a chamber and no other groups except for parties
    it 'includes members of a chamber and no other groups except for parties' do
      expect(Person.only_parliamentary_connections).to contain_exactly(
        zali_federal_parliament_only, alice_nsw_parliament_only, lee_federal_parliament_and_party, bruce_federal_and_nsw_parliament_and_party
      )
    end
  end
end