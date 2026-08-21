class OpenAustralia::Interpretation::ResolvePartyAffiliations
  include OpenAustralia::RawTermDates
  private :contiguous?, :parse_date

  # Checked in order, first match wins. Liberal National Party is checked ahead of the bare
  # Nationals pattern so it resolves to the :liberals family, matching the existing convention
  # in MapGroupNamesAecRecipients (a bare "Liberal National Party" string maps to
  # group_names.liberals.federal, not .nationals.federal).
  MAJOR_PARTY_FAMILIES = [
    [:liberals, /Liberal National Party/i],
    [:nationals, /The Nationals|^Nationals|National Party/i],
    [:labor, /Australian Labor Party/i],
    [:liberals, /Liberal Party/i],
    [:greens, /Australian Greens/i]
  ].freeze

  OFFICE_HOLDER_PARTY_VALUES = %w[Speaker Deputy-Speaker President Deputy-President].freeze

  # OpenAustralia gives Senators their state directly (e.g. "Queensland"), unlike MPs who only
  # get an electorate name (needs MapElectorateToState). This is the full set — a Senate seat is
  # always a state or territory, never an electorate.
  SENATE_STATE_ABBREVIATIONS = {
    'New South Wales' => 'NSW',
    'Victoria' => 'VIC',
    'Queensland' => 'QLD',
    'South Australia' => 'SA',
    'Western Australia' => 'WA',
    'Tasmania' => 'TAS',
    'Northern Territory' => 'NT',
    'Australian Capital Territory' => 'ACT'
  }.freeze

  PartyAffiliationPeriod = Struct.new(
    :party, :major, :federal_group_name, :state, :state_group_name, :start_date, :end_date,
    :family, :superseded_on,
    keyword_init: true
  )
  Result = Struct.new(:party_affiliations, keyword_init: true)

  # Carries a chunk's supersession identity and start date alongside its (possibly absent, for
  # Independent) PartyAffiliationPeriod, so Independent stretches can act as boundary events for
  # supersession purposes without ever appearing in the final output — there's no Group for "no
  # party", but going independent is still real evidence a prior State/Minor Branch ended.
  Chunk = Struct.new(:identity, :start_date, :period, keyword_init: true)

  def self.call(raw_terms) = new(raw_terms).call

  def initialize(raw_terms)
    @terms = raw_terms.sort_by { |term| term['entered_house'] }
  end

  def call
    Result.new(party_affiliations:)
  end

  private

  attr_reader :terms

  def party_affiliations
    chunks = terms_with_effective_party
             .chunk_while { |prev, curr| contiguous?(prev[:term], curr[:term]) && prev[:effective_party] == curr[:effective_party] }
             .map { |group| build_chunk(group) }

    apply_supersession(chunks)
    chunks.filter_map(&:period)
  end

  # A State Branch or Minor Party Membership is closed the moment we observe the person's *next
  # distinct affiliation* — a different state in the same major family, a different major party
  # altogether, a different minor party, or Independent. You can't hold two of these at once, so
  # seeing the next one is real evidence the previous one ended, even though we still don't know
  # when it started (ADR-0005). A state/party that simply *resumes* after a gap — e.g. Barnaby
  # Joyce's two separate Nationals (NSW) stints either side of his 2017 disqualification — is the
  # same identity both times, so it isn't self-superseding.
  #
  # Federal Branch is unaffected: it already closes on its own natural end, which is tied to
  # parliamentary tenure specifically (ADR-0002) — a separate, already-correct signal.
  def apply_supersession(chunks)
    distinct_identities_in_order = chunks.map(&:identity).uniq

    distinct_identities_in_order.each_cons(2) do |current_identity, next_identity|
      supersede_date = chunks.find { |chunk| chunk.identity == next_identity }.start_date

      chunks.select { |chunk| chunk.identity == current_identity && chunk.period }.each do |chunk|
        chunk.period.superseded_on = supersede_date
      end
    end
  end

  def terms_with_effective_party
    terms.each_with_index.map { |term, index| { term: term, effective_party: effective_party_for(term, index) } }
  end

  # ADR-0003: an Office Holder Term (party field overwritten with "Speaker" etc.) is attributed
  # to the most recent preceding Term with a real party, skipping past any other Office Holder
  # (and Independent) Terms in between.
  def effective_party_for(term, index)
    raw_party = term['party'].to_s.strip
    return raw_party unless office_holder?(raw_party)

    terms[0...index].reverse_each do |candidate|
      candidate_party = candidate['party'].to_s.strip
      return candidate_party if real_party?(candidate_party)
    end

    nil
  end

  def office_holder?(party) = OFFICE_HOLDER_PARTY_VALUES.include?(party)
  def independent?(party) = party.blank? || party.match?(/\AIndependent\z/i)
  def real_party?(party) = !independent?(party) && !office_holder?(party)

  # Independent (and an Office Holder Term with no resolvable preceding real party) produce a
  # Chunk with no PartyAffiliationPeriod at all — there's no Group for "no party" — but it still
  # carries an identity and start date, since going independent is itself a supersession trigger.
  def build_chunk(group)
    effective_party = group.first[:effective_party]
    first_term = group.first[:term]
    start_date = parse_date(first_term['entered_house'])

    return Chunk.new(identity: 'independent', start_date: start_date, period: nil) if effective_party.blank? || independent?(effective_party)

    last_term = group.last[:term]
    family = major_party_family(effective_party)
    state = family && state_for(first_term)
    identity = family ? "major:#{family}:#{state}" : "minor:#{effective_party}"

    period = PartyAffiliationPeriod.new(
      party: effective_party,
      major: family.present?,
      federal_group_name: federal_group_name(effective_party, family),
      state: state,
      state_group_name: state && Group::NAMES.send(family).send(state.downcase.to_sym),
      start_date: start_date,
      end_date: parse_date(last_term['left_house']),
      family: family
    )

    Chunk.new(identity: identity, start_date: start_date, period: period)
  end

  def major_party_family(party)
    MAJOR_PARTY_FAMILIES.find { |_family, pattern| pattern.match?(party) }&.first
  end

  # Major parties resolve directly against Group::NAMES — a complete, unambiguous table.
  # Minor parties go through the existing AEC name mapper for its alias-cleanup rules.
  def federal_group_name(party, family)
    return Group::NAMES.send(family).federal if family

    minor_party_mapper.call(party)
  end

  def state_for(term)
    term['house'] == '2' ? senate_state(term['constituency']) : MapElectorateToState.lookup(term['constituency'])
  end

  def senate_state(constituency)
    SENATE_STATE_ABBREVIATIONS[constituency.to_s]
  end

  def minor_party_mapper
    @minor_party_mapper ||= MapGroupNamesAecRecipients.new
  end
end
