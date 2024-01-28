require 'rails_helper'
require 'pry'

# FILEPATH: /Users/john/Projects/John/sunshine_01/spec/models/membership_spec.rb

RSpec.describe Membership, type: :model do
  let(:person) { Person.create(name: 'John Doe') }
  let(:group) { Group.create(name: 'Group 1') }
  let(:membership) { Membership.create(person: person, group: group) }

  describe '#nodes' do
    it 'returns an array containing the person and group of the membership' do
      expect(membership.nodes).to eq([person, group])
    end
  end

  describe '#start_date' do
    context 'when start_date is not set' do
      it 'returns a default start_date' do
        expect(membership.start_date).to eq(Date.new(1900, 1, 1))
      end
    end

    context 'when start_date is set' do
      let(:start_date) { Date.today }
      before { membership.update(start_date: start_date) }

      it 'returns the set start_date' do
        expect(membership.start_date).to eq(start_date)
      end
    end
  end

  describe '#end_date' do
    context 'when end_date is not set' do
      it 'returns a default end_date' do
        expect(membership.end_date).to eq(Date.new(2100, 1, 1))
      end
    end

    context 'when end_date is set' do
      let(:end_date) { Date.today }
      before { membership.update(end_date: end_date) }

      it 'returns the set end_date' do
        expect(membership.end_date).to eq(end_date)
      end
    end
  end

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
    let!(:membership_tony_sabbath) { Membership.create(person: tony, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(2017, 2, 4)) }
    let!(:membership_ozzy_sabbath) { Membership.create(person: ozzy, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(1979, 1, 1)) }
    let!(:membership_geezer_sabbath) { Membership.create(person: geezer, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(1985, 1, 1)) }
    let!(:membership_bill_sabbath) { Membership.create(person: bill, group: sabbath, start_date: Date.new(1968, 1, 1), end_date: Date.new(1984, 1, 1)) }



    let!(:membership_kevin_alp) { Membership.create(person: kevin, group: alp, start_date: Date.new(1999, 1, 1)) }
    let!(:membership_mark_alp) { Membership.create(person: mark, group: alp, start_date: Date.new(1999, 1, 1), end_date: Date.new(2015, 1, 1)) }
    let!(:membership_mark_phon) { Membership.create(person: mark, group: phon, start_date: Date.new(2016, 1, 1), end_date: Date.new(2023, 1, 1)) }
    let!(:membership_pauline_phon) { Membership.create(person: pauline, group: phon, start_date: Date.new(1999, 1, 1)) }

    let!(:curtin) { Person.create(name: 'John Curtin') }
    let!(:membership_curtin_alp) { Membership.create(person: curtin, group: alp, start_date: Date.new(1941, 1, 1), end_date: Date.new(1945, 1, 1)) }

    let!(:howard) { Person.create(name: 'John Howard') }
    let!(:membership_howard_lnp) { Membership.create(person: howard, group: lnp, start_date: Date.new(1985, 1, 1)) }

    let!(:john) { Person.create(name: 'John') }
    let!(:wc_boys) { Group.create(name: 'WC Boys') }
    let!(:cootes) { Group.create(name: 'Cootes') }
    let!(:phader) { Group.create(name: 'Phader') }
    let!(:membership_john_phader) { Membership.create(person: john, group: phader) }
    let!(:membership_john_cootes) { Membership.create(person: john, group: cootes) }
    let!(:membership_john_wc_boys) { Membership.create(person: john, group: wc_boys) }

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

    context 'when there are overlapping memberships', :aggregate_failures do
      it 'returns an array of overlapping memberships' do
        expect(membership_kevin_alp.overlapping).to eq([membership_mark_alp])
        expect(membership_mark_alp.overlapping).to eq([membership_kevin_alp])
        expect(membership_mark_phon.overlapping).to eq([membership_pauline_phon])
        expect(membership_pauline_phon.overlapping).to eq([membership_mark_phon])
      end
    end
  end
end