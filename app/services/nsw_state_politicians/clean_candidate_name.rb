# pastvtr renders candidate names as "SURNAME Given Names" -- the surname (which may itself be
# multiple words, e.g. "MORKOS DOUAIHY Julie") is always the leading run of ALL-CAPS tokens; the
# given name(s) are whatever comes after. This is a different shape than the comma-separated
# "Last, First" People::RecordPerson.clean_name already handles, so it's parsed here rather than
# added to that shared method (which already carries several other sources' accreted, source-
# specific hacks -- see docs/plans/0011-ingest-nsw-state-politicians-design.md).
#
# Examples confirmed against live data:
#   "VOLTZ Lynda"            -> "Lynda Voltz"
#   "MORKOS DOUAIHY Julie"   -> "Julie Morkos Douaihy"
#   "ZAMAN Mohammed (Haseen)" -> "Mohammed (Haseen) Zaman"
class NswStatePoliticians::CleanCandidateName
  def self.call(raw_name) = new(raw_name).call

  def initialize(raw_name)
    @tokens = raw_name.to_s.strip.split(/\s+/)
  end

  def call
    "#{given_tokens.join(' ')} #{surname_tokens.join(' ')}".strip
  end

  private

  attr_reader :tokens

  def surname_tokens
    tokens.take_while { |token| all_caps?(token) }
  end

  def given_tokens
    tokens.drop(surname_tokens.size)
  end

  def all_caps?(token)
    letters = token.gsub(/[^[:alpha:]]/, '')
    letters.present? && letters == letters.upcase
  end
end
