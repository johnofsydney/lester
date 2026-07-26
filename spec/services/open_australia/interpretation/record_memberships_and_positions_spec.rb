require 'rails_helper'

RSpec.describe OpenAustralia::Interpretation::RecordMembershipsAndPositions, type: :service do
  let(:fixture_dir) { Rails.root.join('spec/fixtures/open_australia') }
  let(:parliament_group) { create(:group, name: 'australian federal parliament') }

  before do
    allow(Group).to receive(:federal_parliament).and_return(parliament_group)
  end

  describe 'a person with no OpenAustralia data' do
    let(:person) { create(:person, open_australia_data: []) }

    it 'does nothing' do
      expect { described_class.call(person: person) }.not_to change(Membership, :count)
    end
  end

  describe 'Barnaby Joyce (real data) — Major party, chamber change, gap, Minor party switch' do
    subject(:call) { described_class.call(person: person) }

    let(:raw_terms) do
      rep_terms = JSON.parse(File.read(fixture_dir.join('get_representative_barnaby_joyce.json')))
      sen_terms = JSON.parse(File.read(fixture_dir.join('get_senator_barnaby_joyce.json')))
      (rep_terms + sen_terms).sort_by { |t| t['entered_house'] }
    end
    let(:person) { create(:person, name: 'barnaby joyce', open_australia_data: raw_terms) }

    it 'creates one Parliament Membership per parliament period, each with a matching Position' do
      call

      memberships = Membership.where(member: person, group: parliament_group).order(:start_date)
      expect(memberships.size).to eq(3)

      expect(memberships[0]).to have_attributes(
        start_date: Date.new(2005, 7, 1), end_date: Date.new(2013, 8, 8), evidence: described_class::EVIDENCE_URL
      )
      expect(memberships[0].positions.sole.title).to eq('Senator (Queensland)')

      expect(memberships[1]).to have_attributes(start_date: Date.new(2013, 9, 7), end_date: Date.new(2017, 10, 27))
      expect(memberships[1].positions.sole.title).to eq('MP')

      expect(memberships[2]).to have_attributes(start_date: Date.new(2017, 12, 2), end_date: nil)
      expect(memberships[2].positions.sole.title).to eq('MP')
    end

    it 'creates Federal Branch Memberships for each Nationals stint, closed at the right dates' do
      call

      federal_group = Group.find_by(name: 'nationals (federal)')
      memberships = Membership.where(member: person, group: federal_group).order(:start_date)

      expect(memberships.size).to eq(3)
      expect(memberships.map(&:end_date)).to eq([Date.new(2013, 8, 8), Date.new(2017, 10, 27), Date.new(2025, 11, 27)])
      expect(memberships.first.positions.sole.title).to eq('Federal Parliamentary Party Member')
    end

    it 'creates State Branch Memberships, never closed, one per state (QLD then NSW), not duplicated across the gap' do
      call

      qld_group = Group.find_by(name: 'liberal national party (qld)')
      nsw_group = Group.find_by(name: 'nationals (nsw)')

      qld_memberships = Membership.where(member: person, group: qld_group)
      nsw_memberships = Membership.where(member: person, group: nsw_group)

      expect(qld_memberships.size).to eq(1)
      expect(qld_memberships.first).to have_attributes(start_date: Date.new(2005, 7, 1), end_date: nil)
      expect(qld_memberships.first.positions.sole.title).to eq('Party Member (QLD)')

      expect(nsw_memberships.size).to eq(1)
      expect(nsw_memberships.first).to have_attributes(start_date: Date.new(2013, 9, 7), end_date: nil)
      expect(nsw_memberships.first.positions.sole.title).to eq('Party Member (NSW)')
    end

    it 'creates a never-closed Minor Party Membership for the One Nation switch, and none for the Independent gap' do
      call

      one_nation_group = Group.find_by(name: "Pauline Hanson's One Nation")
      expect(one_nation_group).to be_present

      memberships = Membership.where(member: person, group: one_nation_group)
      expect(memberships.size).to eq(1)
      expect(memberships.first).to have_attributes(start_date: Date.new(2025, 12, 8), end_date: nil)
      expect(memberships.first.positions.sole.title).to eq('Party Member')

      expect(Group.find_by(name: 'independent')).to be_nil
    end

    it 'is idempotent — running it twice does not duplicate any Membership or Position' do
      call
      membership_count = Membership.count
      position_count = Position.count

      described_class.call(person: person)

      expect(Membership.count).to eq(membership_count)
      expect(Position.count).to eq(position_count)
    end
  end

  describe 'Milton Dick (real data) — Office Holder inheritance across a chamber office' do
    subject(:call) { described_class.call(person: person) }

    let(:raw_terms) { JSON.parse(File.read(fixture_dir.join('get_representative_milton_dick.json'))) }
    let(:person) { create(:person, name: 'milton dick', open_australia_data: raw_terms) }

    it 'creates one continuous Parliament Membership spanning the Speaker term, titled MP throughout' do
      call

      memberships = Membership.where(member: person, group: parliament_group)
      expect(memberships.size).to eq(1)
      expect(memberships.first).to have_attributes(start_date: Date.new(2016, 7, 2), end_date: nil)
      expect(memberships.first.positions.sole.title).to eq('MP')
    end

    it 'creates one open Federal Branch Labor Membership spanning the Speaker term, not two' do
      call

      federal_group = Group.find_by(name: 'alp (federal)')
      memberships = Membership.where(member: person, group: federal_group)
      expect(memberships.size).to eq(1)
      expect(memberships.first).to have_attributes(start_date: Date.new(2016, 7, 2), end_date: nil)
    end
  end

  describe 're-running after new data closes a previously-open period' do
    let(:raw_terms) { JSON.parse(File.read(fixture_dir.join('get_representative_milton_dick.json'))) }
    let(:person) { create(:person, name: 'milton dick', open_australia_data: raw_terms) }

    it 'updates end_date on the existing Membership and Position rather than creating a new one' do
      described_class.call(person: person)

      closed_terms = raw_terms.map { |t| t.merge('left_house' => t['left_house'] == '9999-12-31' ? '2026-06-01' : t['left_house']) }
      person.update!(open_australia_data: closed_terms)

      expect { described_class.call(person: person) }.not_to change(Membership, :count)

      membership = Membership.where(member: person, group: parliament_group).sole
      expect(membership.end_date).to eq(Date.new(2026, 6, 1))
      expect(membership.positions.sole.end_date).to eq(Date.new(2026, 6, 1))
    end
  end
end
