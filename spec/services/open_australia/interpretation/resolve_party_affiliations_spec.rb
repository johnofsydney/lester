require 'rails_helper'

RSpec.describe OpenAustralia::Interpretation::ResolvePartyAffiliations, type: :service do
  subject(:result) { described_class.call(raw_terms) }

  let(:fixture_dir) { Rails.root.join('spec/fixtures/open_australia') }

  describe 'a Major party MP and Senator, with a gap and a switch to a Minor party (Barnaby Joyce, real data)' do
    let(:raw_terms) do
      rep_terms = JSON.parse(File.read(fixture_dir.join('get_representative_barnaby_joyce.json')))
      sen_terms = JSON.parse(File.read(fixture_dir.join('get_senator_barnaby_joyce.json')))
      (rep_terms + sen_terms).sort_by { |t| t['entered_house'] }
    end

    it 'produces one affiliation period per non-contiguous stint, dropping the Independent gap entirely' do
      periods = result.party_affiliations

      expect(periods.map(&:party)).to eq([
                                           'National Party',
                                           'National Party',
                                           'National Party',
                                           "Pauline Hanson's One Nation Party"
                                         ])
    end

    it 'resolves the Senate (Queensland) stint to the Nationals federal and QLD groups' do
      period = result.party_affiliations[0]

      expect(period).to have_attributes(
        major: true,
        federal_group_name: 'nationals (federal)',
        state: 'QLD',
        state_group_name: 'liberal national party (qld)',
        start_date: Date.new(2005, 7, 1),
        end_date: Date.new(2013, 8, 8)
      )
    end

    it 'resolves both New England (NSW) House stints to the Nationals federal and NSW groups, kept separate by the 2017 gap' do
      first_house_stint = result.party_affiliations[1]
      second_house_stint = result.party_affiliations[2]

      expect(first_house_stint).to have_attributes(
        major: true, federal_group_name: 'nationals (federal)', state: 'NSW', state_group_name: 'nationals (nsw)',
        start_date: Date.new(2013, 9, 7), end_date: Date.new(2017, 10, 27)
      )
      expect(second_house_stint).to have_attributes(
        major: true, federal_group_name: 'nationals (federal)', state: 'NSW', state_group_name: 'nationals (nsw)',
        start_date: Date.new(2017, 12, 2), end_date: Date.new(2025, 11, 27)
      )
    end

    it 'resolves the Minor party switch with no state split, via the AEC name mapper' do
      period = result.party_affiliations.last

      expect(period).to have_attributes(
        major: false,
        federal_group_name: "Pauline Hanson's One Nation",
        state: nil,
        state_group_name: nil,
        start_date: Date.new(2025, 12, 8),
        end_date: nil
      )
    end
  end

  describe 'an Office Holder term inheriting party across a chamber office (Milton Dick, real data — current Speaker)' do
    let(:raw_terms) { JSON.parse(File.read(fixture_dir.join('get_representative_milton_dick.json'))) }

    it 'merges the Speaker term into the preceding Labor affiliation, per ADR-0003' do
      periods = result.party_affiliations

      expect(periods.size).to eq(1)
      expect(periods.first).to have_attributes(
        party: 'Australian Labor Party',
        major: true,
        federal_group_name: 'alp (federal)',
        state: 'QLD',
        state_group_name: 'alp (qld)',
        start_date: Date.new(2016, 7, 2),
        end_date: nil
      )
    end
  end

  describe 'two consecutive Office Holder terms (synthetic — not exercised by real data)' do
    let(:raw_terms) do
      [
        { 'house' => '1', 'party' => 'Australian Greens', 'constituency' => 'Melbourne',
          'entered_house' => '2010-08-21', 'left_house' => '2016-05-08' },
        { 'house' => '1', 'party' => 'Deputy-Speaker', 'constituency' => 'Melbourne',
          'entered_house' => '2016-05-08', 'left_house' => '2019-04-11' },
        { 'house' => '1', 'party' => 'Speaker', 'constituency' => 'Melbourne',
          'entered_house' => '2019-04-11', 'left_house' => '9999-12-31' }
      ]
    end

    it 'skips past the Deputy-Speaker term to attribute both Office Holder terms to the same preceding real party' do
      periods = result.party_affiliations

      expect(periods.size).to eq(1)
      expect(periods.first).to have_attributes(
        party: 'Australian Greens',
        start_date: Date.new(2010, 8, 21),
        end_date: nil
      )
    end
  end

  describe 'an Office Holder term with no preceding real party (synthetic edge case)' do
    let(:raw_terms) do
      [
        { 'house' => '1', 'party' => 'Speaker', 'constituency' => 'Melbourne',
          'entered_house' => '2010-08-21', 'left_house' => '9999-12-31' }
      ]
    end

    it 'produces no affiliation period, rather than raising' do
      expect(result.party_affiliations).to eq([])
    end
  end
end
