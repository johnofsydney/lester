# NSW LG election cycles, discovered live from pastvtr.elections.nsw.gov.au's own root index --
# no hardcoded list to update as new cycles are declared. Only covers the current site structure's
# `LG<id>` cycles; older cycles (2016, 2012, 2008, 2017) live under a structurally different legacy
# site (LGE<year>/) and aren't covered here.
class Councils::Nsw::Elections
  ROOT_URL = 'https://pastvtr.elections.nsw.gov.au/'.freeze

  class << self
    def find(election_id)
      all.find { |election| election[:id] == election_id } || raise(ArgumentError, "Unknown NSW election_id: #{election_id}")
    end

    def latest
      all.max_by { |election| election[:year] }
    end

    def reset! = @all = nil

    private

    def all
      @all ||= parse(fetch)
    end

    def fetch
      page = Councils::PageDownloader.call(ROOT_URL)
      raise "Failed to download NSW election cycle index: #{ROOT_URL}" if page.blank?

      page
    end

    def parse(page)
      cycles = Councils::Nsw::CycleIndexParser.call(page)
      raise PermanentIngestError, "No NSW LG cycles found on #{ROOT_URL}" if cycles.blank?

      cycles
    end
  end
end
