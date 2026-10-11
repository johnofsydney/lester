# Parses one QLD election's declared results into one normalised contest record per
# mayoral/councillor entry -- takes the raw `<stub>-declared_candidates.json` (the actual declared
# results) and `<stub>-electorates.json` (contest names -- declared_candidates.json only carries
# electorateId/areaCode, not a human name) JSON strings, and joins them on electorateId (confirmed
# 100% match, 343/343 entries, on both the 2020 and 2024 general elections, and on every sampled
# by-election). Pure function of its inputs, no network -- fetching is the caller's job (mirrors
# NSW/VIC, where HTTP lives entirely in the job, e.g. Councils::Nsw::ImportCouncilResultRowJob).
#
# Council name is resolved via Councils::Qld::KnownCouncils' longest-prefix match against the
# contest's electorateName (not via electorates.json's own lgaName field or parentElectorateId --
# neither is populated on by-election files' division-level entries), against the
# `known_council_names:` list the caller passes in -- keeping this parser a pure function of its
# inputs, with no hidden network call through KnownCouncils' own memoized fetch.
class Councils::Qld::DeclaredResultsParser
  # A handful of QLD councils could have no declared result for a cycle because of a state
  # administration scenario, analogous to NSW's s296 self-run/administration cases (see
  # Councils::Nsw::ResultsPageParser::NO_CONTEST_REGEX) -- no live example has been confirmed for
  # QLD yet, so this is a best-effort regex pending a real observed case to tune it against. Checked
  # against each declared-candidates entry's own free-text fields (`eventName`, `paragraph1`,
  # `paragraph2` -- confirmed present on every entry, e.g. "A by-election to fill a vacancy ...").
  NO_CONTEST_REGEX = /administrators? (have been|were|was) appointed|under (the )?administration|no election (was|will be) held/i

  def self.call(declared_candidates_page:, electorates_page:, source_url:, known_council_names:) = new(declared_candidates_page:, electorates_page:, source_url:, known_council_names:).call

  # Checked against a single raw declared-candidates entry (a Hash, straight from its JSON), not a
  # whole downloaded page -- QLD's per-stub JSON covers every council/contest in one file, so unlike
  # NSW/VIC there's no single "page" to check for a specific council's no-contest status.
  def self.no_contest_expected?(entry)
    [entry['eventName'], entry['paragraph1'], entry['paragraph2']].join(' ').match?(NO_CONTEST_REGEX)
  end

  # Pure function of its inputs like .call (see class-level comment) -- surfaces the known council
  # name for any entry whose free text matches NO_CONTEST_REGEX despite having no declared_date, so
  # the caller (Councils::Qld::ImportElectionResultsJob) can route it to the arbitrary-website
  # fallback rather than silently treating it as "not yet declared".
  def self.no_contest_council_names(declared_candidates_page:, electorates_page:, known_council_names:)
    new(declared_candidates_page:, electorates_page:, source_url: nil, known_council_names:).no_contest_council_names
  end

  def initialize(declared_candidates_page:, electorates_page:, source_url:, known_council_names:)
    @declared_candidates_page = declared_candidates_page
    @electorates_page = electorates_page
    @source_url = source_url
    @known_council_names = known_council_names
  end

  def call
    declared_candidates.filter_map { |entry| contest_from(entry) }
  end

  def no_contest_council_names
    declared_candidates.filter_map { |entry| no_contest_council_name_from(entry) }
  end

  private

  attr_reader :declared_candidates_page, :electorates_page, :source_url, :known_council_names

  def no_contest_council_name_from(entry)
    return nil if parse_declared_date(entry['declarationDate']).present? # already declared -- nothing to flag
    return nil unless self.class.no_contest_expected?(entry)

    electorate_name = electorate_names[entry['electorateId']]
    return nil if electorate_name.blank?

    Councils::Qld::KnownCouncils.resolve(electorate_name, within: known_council_names)
  end

  def contest_from(entry)
    electorate_name = electorate_names[entry['electorateId']]
    return nil if electorate_name.blank? # no matching electorate record -- nothing to resolve a council from

    council_name = Councils::Qld::KnownCouncils.resolve(electorate_name, within: known_council_names)
    if council_name.blank?
      # known_council_names only covers the latest general election -- an older election or
      # by-election can reference a council that's since renamed/amalgamated and no longer
      # prefix-matches. Skip just this contest rather than aborting the whole election's parse.
      Rails.logger.warn "Councils::Qld::DeclaredResultsParser: could not resolve a known QLD council for electorateName: #{electorate_name.inspect} -- skipping"
      return nil
    end

    declared_date = parse_declared_date(entry['declarationDate'])
    return nil if declared_date.nil? # not yet declared -- nothing to record yet

    {
      council_name:,
      contest_name: electorate_name,
      contest_type: entry['contest'],
      candidates: candidates_from(entry),
      declared_date:,
      source_url:
    }
  end

  def candidates_from(entry)
    if entry['declaredCandidate'].present?
      [{ name: entry['declaredCandidate'], party: entry['declaredCandidateParty'] }]
    else
      entry.fetch('declaredCandidates', []).map { |candidate| { name: candidate['declaredCandidate'], party: candidate['declaredCandidateParty'] } }
    end
  end

  def parse_declared_date(declaration_date)
    return nil if declaration_date.blank?

    Date.parse(declaration_date)
  end

  def declared_candidates
    JSON.parse(declared_candidates_page)['declaredCandidates']
  end

  def electorate_names
    @electorate_names ||= JSON.parse(electorates_page)['electorates']
                              .index_by { |electorate| electorate['electorateId'] }
                              .transform_values { |electorate| electorate['electorateName'] }
  end
end
