# Placeholder fallback for a council whose electoral commission has no election results to ingest
# for a cycle (e.g. a NSW council running its own election under s296, or a VIC/QLD council under
# state-appointed administration) -- eventually responsible for coordinating a fetch of that
# council's leadership (councillors, mayor) straight from its own website instead. Not yet built --
# see docs/plans/0002-local-council-councillor-ingestion.md for why the prior LeadershipWebsite
# scraper was deleted rather than kept, and issue #338 for this fallback's motivation. For now this
# just logs the council name it was asked to handle.
class Councils::ArbitraryLeadershipWebsiteIngestJob
  include Sidekiq::Job

  sidekiq_options queue: :low

  def perform(council_name)
    Rails.logger.info "Councils::ArbitraryLeadershipWebsiteIngestJob: no electoral-commission results for #{council_name.inspect} -- arbitrary leadership website ingest not yet implemented"
  end
end
