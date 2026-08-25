# Resolves any QLD contest's council name from its electorateName -- e.g. "Aurukun Shire Division
# 1" or "Brisbane City Coorparoo" (Brisbane uses named wards, not numbered divisions) both resolve
# to their council via longest-matching-prefix against a cached list of QLD's 77 council names.
#
# This is the one algorithm that works uniformly across both file shapes ECQ publishes:
# - a general election's `-electorates.json` has a top-level "lgaName" field on the council's own
#   (mayoral) entry, but not on its per-division entries
# - a by-election's `-electorates.json` has exactly one electorate (itself), with no
#   parentElectorateId and no lgaName at all to resolve a council name from directly
#
# Council names are sourced from the latest general election (Councils::Qld::Elections
# .latest_general) rather than hardcoded -- confirmed live, every division/ward's electorateName
# begins with its council's exact lgaName, in both the 2020 and 2024 general elections and every
# sampled by-election.
class Councils::Qld::KnownCouncils
  ELECTORATES_URL = 'https://resultsdata.elections.qld.gov.au/%<stub>s-electorates.json'.freeze

  class << self
    # Memoized at class level (not per-instance) so a full ingest run's ~45 stub jobs, once one of
    # them has paid for the fetch, reuse the same 77-name list rather than each paying for it
    # again -- the list only ever changes when a new general election cycle appears.
    def resolve(electorate_name)
      names.find { |name| electorate_name.start_with?(name) }
    end

    def reset! = @names = nil

    private

    def names
      @names ||= fetch_names.sort_by { |name| -name.length }
    end

    def fetch_names
      stub = Councils::Qld::Elections.latest_general.fetch(:stub)
      url = format(ELECTORATES_URL, stub:)
      page = Councils::PageDownloader.call(url)
      raise "Failed to download QLD electorates for known-council names: #{url}" if page.blank?

      JSON.parse(page)['electorates'].filter_map { |electorate| electorate['lgaName'] }
    end
  end
end
