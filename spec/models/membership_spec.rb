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

    let!(:membership_kevin_alp) { Membership.create(person: kevin, group: alp, start_date: Date.new(1999, 1, 1)) }
    let!(:membership_mark_alp) { Membership.create(person: mark, group: alp, start_date: Date.new(1999, 1, 1), end_date: Date.new(2015, 1, 1)) }
    let!(:membership_mark_phon) { Membership.create(person: mark, group: phon, start_date: Date.new(2016, 1, 1), end_date: Date.new(2023, 1, 1)) }
    let!(:membership_pauline_phon) { Membership.create(person: pauline, group: phon, start_date: Date.new(1999, 1, 1)) }

    let!(:curtin) { Person.create(name: 'John Curtin') }
    let!(:membership_curtin_alp) { Membership.create(person: curtin, group: alp, start_date: Date.new(1941, 1, 1), end_date: Date.new(1945, 1, 1)) }

    let!(:howard) { Person.create(name: 'John Howard') }
    let!(:membership_howard_lnp) { Membership.create(person: howard, group: lnp, start_date: Date.new(1985, 1, 1)) }

    context 'when there are no overlapping memberships' do
      it 'returns an empty array' do
        expect(membership_howard_lnp.overlapping).to eq([])
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