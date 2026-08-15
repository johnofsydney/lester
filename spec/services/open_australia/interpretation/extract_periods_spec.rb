require 'rails_helper'

RSpec.describe OpenAustralia::Interpretation::ExtractPeriods, type: :service do
  subject(:result) { described_class.call(raw_terms) }

  let(:fixture_dir) { Rails.root.join('spec/fixtures/open_australia') }

  describe 'a single, still-serving term (Anthony Albanese)' do
    let(:raw_terms) { JSON.parse(File.read(fixture_dir.join('get_representative_albanese.json'))) }

    it 'returns one parliament period, open-ended' do
      expect(result.parliament_periods.size).to eq(1)
      expect(result.parliament_periods.first).to have_attributes(
        house: '1',
        position: 'MP',
        constituency: 'Grayndler',
        start_date: Date.new(1996, 3, 2),
        end_date: nil
      )
    end

    it 'returns one party period, open-ended' do
      expect(result.party_periods.size).to eq(1)
      expect(result.party_periods.first).to have_attributes(
        party: 'Australian Labor Party',
        start_date: Date.new(1996, 3, 2),
        end_date: nil
      )
    end
  end

  describe 'a politician who changed house, lost and regained their seat, then changed party twice (Barnaby Joyce, real data)' do
    let(:raw_terms) do
      rep_terms = JSON.parse(File.read(fixture_dir.join('get_representative_barnaby_joyce.json')))
      sen_terms = JSON.parse(File.read(fixture_dir.join('get_senator_barnaby_joyce.json')))
      (rep_terms + sen_terms).sort_by { |t| t['entered_house'] }
    end

    it 'splits parliament service into three periods: Senate, House, House (spanning the party changes)' do
      periods = result.parliament_periods

      expect(periods.size).to eq(3)

      expect(periods[0]).to have_attributes(
        house: '2', position: 'Senator (Queensland)', constituency: 'Queensland',
        start_date: Date.new(2005, 7, 1), end_date: Date.new(2013, 8, 8)
      )
      expect(periods[1]).to have_attributes(
        house: '1', position: 'MP', constituency: 'New England',
        start_date: Date.new(2013, 9, 7), end_date: Date.new(2017, 10, 27)
      )
      expect(periods[2]).to have_attributes(
        house: '1', position: 'MP', constituency: 'New England',
        start_date: Date.new(2017, 12, 2), end_date: nil
      )
    end

    it 'does not merge across the 2017 disqualification gap even though the house is unchanged either side' do
      periods = result.parliament_periods

      expect(periods[1].end_date).to eq(Date.new(2017, 10, 27))
      expect(periods[2].start_date).to eq(Date.new(2017, 12, 2))
    end

    it 'splits party affiliation into five periods, including two separate National Party stints either side of the gap' do
      periods = result.party_periods

      expect(periods.map(&:party)).to eq([
                                           'National Party',
                                           'National Party',
                                           'National Party',
                                           'Independent',
                                           "Pauline Hanson's One Nation Party"
                                         ])
    end

    it 'keeps the two National Party periods separate even though the party string is identical' do
      periods = result.party_periods

      first_nationals = periods[0]
      second_nationals = periods[1]
      third_nationals = periods[2]

      expect(first_nationals).to have_attributes(start_date: Date.new(2005, 7, 1), end_date: Date.new(2013, 8, 8))
      expect(second_nationals).to have_attributes(start_date: Date.new(2013, 9, 7), end_date: Date.new(2017, 10, 27))
      expect(third_nationals).to have_attributes(start_date: Date.new(2017, 12, 2), end_date: Date.new(2025, 11, 27))
    end

    it 'breaks a party period on a same-day party change even with zero date gap' do
      periods = result.party_periods

      independent_period = periods.find { |p| p.party == 'Independent' }
      one_nation_period = periods.find { |p| p.party == "Pauline Hanson's One Nation Party" }

      expect(independent_period).to have_attributes(start_date: Date.new(2025, 11, 27), end_date: Date.new(2025, 12, 8))
      expect(one_nation_period).to have_attributes(start_date: Date.new(2025, 12, 8), end_date: nil)
    end
  end

  describe 'changing house with no date gap and no party change (synthetic)' do
    let(:raw_terms) do
      [
        {
          'house' => '2', 'party' => 'Australian Greens', 'constituency' => 'Tasmania',
          'entered_house' => '2010-07-01', 'left_house' => '2020-06-30'
        },
        {
          'house' => '1', 'party' => 'Australian Greens', 'constituency' => 'Melbourne',
          'entered_house' => '2020-06-30', 'left_house' => '9999-12-31'
        }
      ]
    end

    it 'still splits into two parliament periods, since the house changed' do
      expect(result.parliament_periods.size).to eq(2)
      expect(result.parliament_periods.map(&:house)).to eq(%w[2 1])
    end

    it 'treats the party period as continuous across the house change, since the party string and dates both hold' do
      expect(result.party_periods.size).to eq(1)
      expect(result.party_periods.first).to have_attributes(
        party: 'Australian Greens',
        start_date: Date.new(2010, 7, 1),
        end_date: nil
      )
    end
  end

  describe 'unsorted input' do
    let(:raw_terms) do
      [
        { 'house' => '1', 'party' => 'Independent', 'constituency' => 'X', 'entered_house' => '2020-01-01', 'left_house' => '9999-12-31' },
        { 'house' => '1', 'party' => 'Independent', 'constituency' => 'X', 'entered_house' => '2010-01-01', 'left_house' => '2020-01-01' }
      ]
    end

    it 'sorts by entered_house before grouping, regardless of input order' do
      expect(result.parliament_periods.size).to eq(1)
      expect(result.parliament_periods.first.start_date).to eq(Date.new(2010, 1, 1))
    end
  end
end
