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
  def self.call(declared_candidates_page:, electorates_page:, source_url:, known_council_names:) = new(declared_candidates_page:, electorates_page:, source_url:, known_council_names:).call

  def initialize(declared_candidates_page:, electorates_page:, source_url:, known_council_names:)
    @declared_candidates_page = declared_candidates_page
    @electorates_page = electorates_page
    @source_url = source_url
    @known_council_names = known_council_names
  end

  def call
    declared_candidates.filter_map { |entry| contest_from(entry) }
  end

  private

  attr_reader :declared_candidates_page, :electorates_page, :source_url, :known_council_names

  def contest_from(entry)
    electorate_name = electorate_names[entry['electorateId']]
    return nil if electorate_name.blank? # no matching electorate record -- nothing to resolve a council from

    council_name = Councils::Qld::KnownCouncils.resolve(electorate_name, within: known_council_names)
    raise "Could not resolve a known QLD council for electorateName: #{electorate_name.inspect}" if council_name.blank?

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
