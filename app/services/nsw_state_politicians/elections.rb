# Known NSW state general election cycles reachable via the current pastvtr.elections.nsw.gov.au
# site structure, oldest first. Mirrors Councils::Nsw::Elections' shape.
#
# 2015 and earlier live under a structurally different legacy path
# (pastvtr.elections.nsw.gov.au/SGE{year}/...) -- not covered here, tracked separately as
# https://github.com/johnofsydney/lester/issues/290. By-elections are also not covered -- they're
# single-electorate events with their own separate result pages, not part of a general-election
# sweep (see docs/plans/0011-ingest-nsw-state-politicians-design.md).
module NswStatePoliticians::Elections
  ALL = [
    { id: 'SG1901', year: 2019 },
    { id: 'SG2301', year: 2023 }
  ].freeze

  def self.find(event_id)
    ALL.find { |election| election[:id] == event_id } || raise(ArgumentError, "Unknown NSW state election_id: #{event_id}")
  end

  def self.latest
    ALL.last
  end
end
