# Known VIC council election cycles reachable via the current vec.vic.gov.au site structure,
# oldest first. Older cycles (2017, 2016, 2012, 2008) live under a structurally different legacy
# site and aren't covered here.
#
# election_date is the state-wide polling day, used to override declared_date for any non-latest
# cycle -- archived pages' "Last updated" stamp reflects whenever VEC last regenerated the page
# (confirmed live: 2020 council pages all report "Last updated: 22 November 2024"), not the real
# 2020 declaration date, so it can't be trusted. The latest cycle's page-level date is trusted
# as-is instead, since it's genuinely accurate while the election is current.
module Councils::Vic::Elections
  ALL = [
    { year: 2020, election_date: Date.new(2020, 10, 24) },
    { year: 2024, election_date: Date.new(2024, 10, 26) }
  ].freeze

  def self.find(election_year)
    ALL.find { |election| election[:year] == election_year } || raise(ArgumentError, "Unknown VIC election_year: #{election_year}")
  end

  def self.latest
    ALL.last
  end

  def self.latest?(election_year)
    election_year == latest[:year]
  end
end
