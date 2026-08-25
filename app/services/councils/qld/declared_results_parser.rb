# Parses one QLD election stub's declared results into one normalised contest record per
# mayoral/councillor entry -- fetches `<stub>-declared_candidates.json` (the actual declared
# results) and `<stub>-electorates.json` (contest names -- declared_candidates.json only carries
# electorateId/areaCode, not a human name), and joins them on electorateId (confirmed 100% match,
# 343/343 entries, on both the 2020 and 2024 general elections, and on every sampled by-election).
#
# Council name is resolved via Councils::Qld::KnownCouncils' longest-prefix match against the
# contest's electorateName, not via electorates.json's own lgaName field or parentElectorateId --
# neither is populated on by-election files' division-level entries.
class Councils::Qld::DeclaredResultsParser
  DECLARED_CANDIDATES_URL = 'https://resultsdata.elections.qld.gov.au/%<stub>s-declared_candidates.json'.freeze
  ELECTORATES_URL = 'https://resultsdata.elections.qld.gov.au/%<stub>s-electorates.json'.freeze

  def self.call(stub) = new(stub).call

  def initialize(stub)
    @stub = stub
  end

  def call
    electorate_names = fetch_electorate_names
    fetch_declared_candidates.filter_map { |entry| contest_from(entry, electorate_names) }
  end

  private

  attr_reader :stub

  def contest_from(entry, electorate_names)
    electorate_name = electorate_names[entry['electorateId']]
    return nil if electorate_name.blank? # no matching electorate record -- nothing to resolve a council from

    council_name = Councils::Qld::KnownCouncils.resolve(electorate_name)
    raise "Could not resolve a known QLD council for electorateName: #{electorate_name.inspect}" if council_name.blank?

    declared_date = parse_declared_date(entry['declarationDate'])
    return nil if declared_date.nil? # not yet declared -- nothing to record yet

    {
      council_name:,
      contest_name: electorate_name,
      contest_type: entry['contest'],
      candidates: candidates_from(entry),
      declared_date:,
      source_url: declared_candidates_url
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

  def fetch_declared_candidates
    page = Councils::PageDownloader.call(declared_candidates_url)
    raise "Failed to download QLD declared candidates: #{declared_candidates_url}" if page.blank?

    JSON.parse(page)['declaredCandidates']
  end

  def fetch_electorate_names
    page = Councils::PageDownloader.call(electorates_url)
    raise "Failed to download QLD electorates: #{electorates_url}" if page.blank?

    JSON.parse(page)['electorates'].index_by { |electorate| electorate['electorateId'] }
        .transform_values { |electorate| electorate['electorateName'] }
  end

  def declared_candidates_url = format(DECLARED_CANDIDATES_URL, stub:)
  def electorates_url = format(ELECTORATES_URL, stub:)
end
