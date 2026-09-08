# QLD local government elections (general + by-election), discovered live from the Electoral
# Commission of Queensland's own election index -- unlike NSW/VIC there is no fixed, hand-maintained
# list to keep in sync: elections.json already carries every QLD election since 2020, state and
# local, general and by-election, correctly typed via electionType.
class Councils::Qld::Elections
  ELECTIONS_URL = 'https://resultsdata.elections.qld.gov.au/elections.json'.freeze
  LOCAL_ELECTION_TYPES = ['Local Quadrennial', 'Local Councillor By-election', 'Local Mayoral By-election'].freeze

  class << self
    # Memoized at class level (not per-instance) so a full ingest run's IngestElectionResultsJob and
    # KnownCouncils calls -- which each need the elections index -- share one fetch instead of two.
    def local
      all.select { |election| LOCAL_ELECTION_TYPES.include?(election[:election_type]) }
    end

    # The most recent general (quadrennial) election -- used as the source for
    # Councils::Qld::KnownCouncils' council-name list. Picked by election_day, not the API's own
    # `current` flag (confirmed live: `current` is false for both the 2020 and 2024 general
    # elections, so it can't distinguish "most recent" from "not currently being counted").
    def latest_general
      all.select { |election| election[:election_type] == 'Local Quadrennial' }
         .max_by { |election| election[:election_day] }
    end

    def reset! = @all = nil

    private

    def all
      @all ||= parse(fetch)
    end

    def fetch
      page = Councils::PageDownloader.call(ELECTIONS_URL)
      raise "Failed to download QLD elections index: #{ELECTIONS_URL}" if page.blank?

      page
    end

    def parse(page)
      JSON.parse(page)['elections'].map do |election|
        {
          stub: election['stub'],
          election_type: election['electionType'],
          election_name: election['electionName'],
          election_day: Date.parse(election['electionDay'])
        }
      end
    end
  end
end
