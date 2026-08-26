# Maps a ballot/results-page party label (e.g. "Australian Labor Party (NSW Branch)")
# to the existing state-branch party Tag Group (Group::NAMES), or nil when the label
# doesn't match a major party (independents, local tickets, minor parties, blank).
class Councils::PartyMapper
  KEYWORDS_TO_NAMES_KEY = {
    /labor/i => :labor,
    /liberal/i => :liberals,
    /national/i => :nationals,
    /greens/i => :greens
  }.freeze

  # Non-family minor parties that still have their own (non-state-branched) Group in the DB --
  # checked before the family keyword match below. Without this, a label like "Liberal Democratic
  # Party" would wrongly match /liberal/i and resolve into the actual Liberal Party's Group -- LDP
  # has no entry in Group::NAMES at all (it's not one of the four major families), so it needs its
  # own direct name here rather than a family lookup.
  EXPLICIT_NAMES = {
    /liberal democrat/i => 'Liberal Democratic Party'
  }.freeze

  def self.call(party_label, state:)
    new(party_label, state:).call
  end

  # The canonical Group name this label would resolve to, regardless of whether that Group
  # already exists -- for callers that need to create the Group (e.g. a winning candidate's party
  # always gets a Group, per docs/plans/0011-ingest-nsw-state-politicians-design.md), as opposed
  # to `call`, which only returns an *existing* Group (used to gate whether an unsuccessful
  # candidate is worth ingesting at all).
  def self.resolved_name(party_label, state:)
    new(party_label, state:).resolved_name
  end

  def initialize(party_label, state:)
    @party_label = party_label
    @state = state
  end

  def call
    return nil if party_label.blank?
    return nil if resolved_name.blank?

    Group.find_by_name_i(resolved_name) # rubocop:disable Rails/DynamicFindBy -- this is Group's own custom lookup method, not an AR dynamic finder
  end

  def resolved_name
    return nil if party_label.blank?

    explicit_name || family_name
  end

  private

  attr_reader :party_label, :state

  def explicit_name
    EXPLICIT_NAMES.find { |pattern, _name| party_label.match?(pattern) }&.last
  end

  def family_name
    names_key = matching_names_key
    return nil if names_key.nil?

    Group::NAMES.send(names_key)&.send(state)
  end

  # A joint ticket (e.g. "LIBERAL / THE NATIONALS") resolves to whichever party is named first --
  # only match keywords against the text before the first "/", so a two-party ticket can't
  # accidentally match on the second party's keyword instead of the first. Decided: first-named
  # wins, not both, not neither -- implemented generically (not hardcoded to Liberal/Nationals) so
  # it holds for any joint-ticket label this or a future election surfaces.
  def matching_names_key
    first_named_party = party_label.split('/').first.to_s
    KEYWORDS_TO_NAMES_KEY.find { |pattern, _key| first_named_party.match?(pattern) }&.last
  end
end
