# VIC council election cycles, discovered live from vec.vic.gov.au's own results index -- no
# hardcoded list to update as new cycles occur. Only covers the modern `<year>-council-election-
# results` slug shape (see Councils::Vic::CycleIndexParser); older/legacy and single-council
# special-election cycles aren't covered here, matching this pipeline's existing scope.
#
# election_date is the state-wide polling day, used to override declared_date for any non-latest
# cycle -- archived pages' "Last updated" stamp reflects whenever VEC last regenerated the page
# (confirmed live: 2020 council pages all report "Last updated: 22 November 2024"), not the real
# 2020 declaration date, so it can't be trusted. The latest cycle's page-level date is trusted
# as-is instead, since it's genuinely accurate while the election is current. Computed, not
# fetched: VIC council elections are legislatively fixed to the fourth Saturday in October,
# confirmed against every polling day in this pipeline's scope (2016, 2020, 2024).
class Councils::Vic::Elections
  INDEX_URL = 'https://www.vec.vic.gov.au/results/council-election-results'.freeze

  class << self
    def find(election_year)
      all.find { |election| election[:year] == election_year } || raise(ArgumentError, "Unknown VIC election_year: #{election_year}")
    end

    def latest
      all.max_by { |election| election[:year] }
    end

    def latest?(election_year)
      election_year == latest[:year]
    end

    def reset! = @all = nil

    private

    def all
      @all ||= parse(fetch).map { |cycle| cycle.merge(election_date: fourth_saturday_of_october(cycle[:year])) }
    end

    def fetch
      page = Councils::PageDownloader.call(INDEX_URL)
      raise "Failed to download VIC election cycle index: #{INDEX_URL}" if page.blank?

      page
    end

    def parse(page)
      cycles = Councils::Vic::CycleIndexParser.call(page)
      raise "No VIC council election cycles found on #{INDEX_URL}" if cycles.blank?

      cycles
    end

    def fourth_saturday_of_october(year)
      first_of_october = Date.new(year, 10, 1)
      first_saturday = first_of_october + ((6 - first_of_october.wday) % 7)
      first_saturday + 21
    end
  end
end
