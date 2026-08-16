# Known NSW LG election cycles reachable via the current pastvtr.elections.nsw.gov.au site
# structure, oldest first. Older cycles (2016, 2012, 2008, 2017) live under a structurally
# different legacy site (LGE<year>/) and aren't covered here.
module Councils::Nsw::Elections
  ALL = [
    { id: 'LG2101', year: 2021, election_date: Date.new(2021, 12, 4) },
    { id: 'LG2401', year: 2024, election_date: Date.new(2024, 9, 14) }
  ].freeze

  def self.find(election_id)
    ALL.find { |election| election[:id] == election_id } || raise(ArgumentError, "Unknown NSW election_id: #{election_id}")
  end

  def self.latest
    ALL.last
  end
end
