require 'rails_helper'
require 'pry'

# FILEPATH: /Users/john/Projects/John/sunshine_01/spec/models/membership_spec.rb

RSpec.describe Membership do
  let(:person) { Person.create(name: 'John Doe') }
  let(:group) { Group.create(name: 'Group 1') }
  let(:membership) { described_class.create(member: person, group: group) }
  let!(:charities_group) { Group.create(name: 'Charities') }

  before do
    allow(Group).to receive(:charities_tag).and_return(charities_group)
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:member_type) }
    it { is_expected.to validate_presence_of(:member_id) }
    it { is_expected.to validate_presence_of(:group_id) }
  end

  describe '#nodes' do
    it 'returns an array containing the person and group of the membership' do
      expect(membership.nodes).to eq([person, group])
    end
  end

  describe '.charity_subgroups' do
    let!(:charity1) { Group.create(name: 'Charity 1') }
    let!(:charity2) { Group.create(name: 'Charity 2') }
    let!(:other_group) { Group.create(name: 'Other Group') }
    let!(:person1) { Person.create(name: 'Person 1') }

    let!(:charity_link_1) { described_class.create(group: charities_group, member: charity1) }
    let!(:charity_link_2) { described_class.create(group: charities_group, member: charity2) }
    let!(:other_link) { described_class.create(group: other_group, member: person1) }

    it 'returns memberships where charities has groups as members' do
      expect(described_class.charity_subgroups).to include(charity_link_1, charity_link_2)
    end

    it 'does not include non-charities memberships' do
      expect(described_class.charity_subgroups).not_to include(other_link)
    end

    it 'returns an active record relation' do
      expect(described_class.charity_subgroups).to be_a(ActiveRecord::Relation)
    end
  end

  describe '.person_in_charity' do
    let!(:charities_group) { Group.create(name: 'Charities') }
    let!(:charity1) { Group.create(name: 'Charity 1') }
    let!(:charity2) { Group.create(name: 'Charity 2') }
    let!(:other_group) { Group.create(name: 'Other Group') }

    let!(:person1) { Person.create(name: 'Person 1') }
    let!(:person2) { Person.create(name: 'Person 2') }
    let!(:person3) { Person.create(name: 'Person 3') }

    let!(:charity_link_1) { described_class.create(group: charities_group, member: charity1) }
    let!(:charity_link_2) { described_class.create(group: charities_group, member: charity2) }

    let!(:person1_charity_membership) { described_class.create(group: charity1, member: person1) }
    let!(:person2_charity_membership) { described_class.create(group: charity2, member: person2) }
    let!(:person2_other_membership) { described_class.create(group: other_group, member: person2) }
    let!(:person3_other_membership) { described_class.create(group: other_group, member: person3) }

    it 'returns person memberships where the group is a charities subgroup' do
      expect(described_class.person_in_charity).to include(person1_charity_membership, person2_charity_membership)
    end

    it 'does not include non-charity memberships or group-to-group memberships' do
      expect(described_class.person_in_charity).not_to include(person2_other_membership, person3_other_membership, charity_link_1, charity_link_2)
    end
  end

  # used in BuildQueue
  describe '#overlapping' do
    let!(:kevin) { Person.create(name: 'Kevin') }
    let!(:mark) { Person.create(name: 'Mark') }
    let!(:pauline) { Person.create(name: 'Pauline') }
    let!(:alp) { Group.create(name: 'ALP') }
    let!(:phon) { Group.create(name: 'PHON') }
    let!(:lnp) { Group.create(name: 'LNP') }

    let!(:sabbath) { Group.create(name: 'Black Sabbath') }
    let!(:tony) { Person.create(name: 'Tony') }
    let!(:ozzy) { Person.create(name: 'Ozzy') }
    let!(:geezer) { Person.create(name: 'Geezer') }
    let!(:bill) { Person.create(name: 'Bill') }
    let!(:membership_tony_sabbath) { described_class.create(member: tony, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(2017, 2, 4)) }
    let!(:membership_ozzy_sabbath) { described_class.create(member: ozzy, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(1979, 1, 1)) }
    let!(:membership_geezer_sabbath) { described_class.create(member: geezer, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(1985, 1, 1)) }
    let!(:membership_bill_sabbath) { described_class.create(member: bill, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(1984, 1, 1)) }

    let!(:membership_kevin_alp) { described_class.create(member: kevin, group: alp, start_date: Date.new(1999, 1, 1)) }
    let!(:membership_mark_alp) { described_class.create(member: mark, group: alp, start_date: Date.new(1999, 1, 1), end_date: Date.new(2015, 1, 1)) }
    let!(:membership_mark_phon) { described_class.create(member: mark, group: phon, start_date: Date.new(2016, 1, 1), end_date: Date.new(2023, 1, 1)) }
    let!(:membership_pauline_phon) { described_class.create(member: pauline, group: phon, start_date: Date.new(1999, 1, 1)) }

    let!(:curtin) { Person.create(name: 'John Curtin') }
    let!(:membership_curtin_alp) { described_class.create(member: curtin, group: alp, start_date: Date.new(1941, 1, 1), end_date: Date.new(1945, 1, 1)) }

    let!(:howard) { Person.create(name: 'John Howard') }
    let!(:membership_howard_lnp) { described_class.create(member: howard, group: lnp, start_date: Date.new(1985, 1, 1)) }

    let!(:john) { Person.create(name: 'John') }
    let!(:wc_boys) { Group.create(name: 'WC Boys') }
    let!(:cootes) { Group.create(name: 'Cootes') }
    let!(:phader) { Group.create(name: 'Phader') }
    let!(:membership_john_phader) { described_class.create(member: john, group: phader) }
    let!(:membership_john_cootes) { described_class.create(member: john, group: cootes) }
    let!(:membership_john_wc_boys) { described_class.create(member: john, group: wc_boys) }

    context 'when there are no overlapping memberships' do
      it 'returns an empty array' do
        expect(membership_howard_lnp.overlapping).to eq([])
      end
    end

    context 'when all memberships are overlapping and have start and end dates' do
      it 'returns an array of overlapping memberships' do
        expect(membership_tony_sabbath.overlapping).to contain_exactly(
          membership_ozzy_sabbath,
          membership_geezer_sabbath,
          membership_bill_sabbath
        )
      end
    end

    context 'when there are no overlapping memberships within the time frame' do
      it 'returns an empty array' do
        expect(membership_curtin_alp.overlapping).to eq([])
      end
    end

    # TODO: needs attention
    context 'when there are overlapping memberships', :aggregate_failures do
      xit 'returns an array of overlapping memberships' do
        expect(membership_kevin_alp.overlapping).to eq([membership_mark_alp])
        expect(membership_mark_alp.overlapping).to eq([membership_kevin_alp])
        expect(membership_mark_phon.overlapping).to eq([membership_pauline_phon])
        expect(membership_pauline_phon.overlapping).to eq([membership_mark_phon])
      end
    end
  end
end