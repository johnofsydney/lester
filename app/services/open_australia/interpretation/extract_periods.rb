class OpenAustralia::Interpretation::ExtractPeriods
  include OpenAustralia::Interpretation::RawTermDates
  private :contiguous?, :parse_date

  ParliamentPeriod = Struct.new(:house, :position, :constituency, :start_date, :end_date, keyword_init: true)
  PartyPeriod = Struct.new(:party, :start_date, :end_date, keyword_init: true)
  Result = Struct.new(:parliament_periods, :party_periods, keyword_init: true)

  def self.call(raw_terms) = new(raw_terms).call

  def initialize(raw_terms)
    @terms = raw_terms.sort_by { |term| term['entered_house'] }
  end

  def call
    Result.new(parliament_periods:, party_periods:)
  end

  private

  attr_reader :terms

  # Two consecutive Terms are the same Parliament period when they're date-contiguous
  # (one ends the day the next begins) and in the same house. A real gap (lost seat,
  # later re-elected) always starts a new period, even if the house is unchanged.
  def parliament_periods
    terms.chunk_while { |prev, curr| contiguous?(prev, curr) && prev['house'] == curr['house'] }
         .map { |group| build_parliament_period(group) }
  end

  # Two consecutive Terms are the same party period when they're date-contiguous and
  # report the same raw party string. A real gap ends the current party period even if
  # the party string on the far side is identical — see Barnaby Joyce's two separate
  # "National Party" periods either side of his 2017 disqualification.
  def party_periods
    terms.chunk_while { |prev, curr| contiguous?(prev, curr) && prev['party'] == curr['party'] }
         .map { |group| build_party_period(group) }
  end

  def build_parliament_period(group)
    first = group.first
    last = group.last

    ParliamentPeriod.new(
      house: first['house'],
      position: position_for(first),
      constituency: first['constituency'],
      start_date: parse_date(first['entered_house']),
      end_date: parse_date(last['left_house'])
    )
  end

  def position_for(term)
    term['house'] == '2' ? "Senator (#{term['constituency']})" : 'MP'
  end

  def build_party_period(group)
    first = group.first
    last = group.last

    PartyPeriod.new(
      party: first['party'],
      start_date: parse_date(first['entered_house']),
      end_date: parse_date(last['left_house'])
    )
  end
end
