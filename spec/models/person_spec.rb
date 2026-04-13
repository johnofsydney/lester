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
end