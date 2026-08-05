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

  def self.call(party_label, state:)
    new(party_label, state:).call
  end

  def initialize(party_label, state:)
    @party_label = party_label
    @state = state
  end

  def call
    return nil if party_label.blank?

    names_key = matching_names_key
    return nil if names_key.nil?

    party_group_name = Group::NAMES.send(names_key)&.send(state)
    return nil if party_group_name.blank?

    Group.find_by_name_i(party_group_name) # rubocop:disable Rails/DynamicFindBy -- this is Group's own custom lookup method, not an AR dynamic finder
  end

  private

  attr_reader :party_label, :state

  def matching_names_key
    KEYWORDS_TO_NAMES_KEY.find { |pattern, _key| party_label.match?(pattern) }&.last
  end
end
