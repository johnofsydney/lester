# Backfills the one prior NSW LG election cycle confirmed reachable in the current
# pastvtr.elections.nsw.gov.au site structure (see
# context/2026-08-15-council-ingestion-production-readiness-goal-2.md for the live research
# behind that scope decision). Run once, from /maintenance_tasks, after the latest cycle is
# already imported -- Councils::Nsw::ImportCouncilResultRowJob relies on that to correctly tell
# a councillor who continued serving apart from one who didn't return after this older term.
module Maintenance
  class BackfillNswCouncilElectionResultsTask < MaintenanceTasks::Task
    BACKFILL_ELECTION_ID = Councils::Nsw::Elections::ALL.first[:id]

    def collection
      @collection ||= fetch_councils
    end
    delegate :count, to: :collection

    # Enqueues rather than calling ImportCouncilResultRowJob's #perform directly, so a single
    # council's failure retries and eventually dead-letters via Sidekiq's own machinery (which
    # sidekiq_options(retry: 3, ...) relies on) instead of raising straight out of #process and
    # halting the whole task run. Spaced the same way as the normal fan-out
    # (Councils::Nsw::IngestElectionResultsJob) so ~128 near-instant enqueues don't hammer NSWEC
    # once Sidekiq's 5 concurrent workers pick them up.
    def process(council)
      delay = collection.index(council) * Councils::Nsw::IngestElectionResultsJob::IMPORT_SPACING
      Councils::Nsw::ImportCouncilResultRowJob.perform_in(delay, council[:name], council[:slug], BACKFILL_ELECTION_ID)
    end

    private

    def fetch_councils
      page = Councils::PageDownloader.call(index_url)
      raise "Failed to download NSW council index: #{index_url}" if page.blank?

      councils = Councils::Nsw::ResultsIndexParser.call(page)
      raise "No councils found on NSW council index: #{index_url}" if councils.blank?

      councils
    end

    def index_url
      "https://pastvtr.elections.nsw.gov.au/#{BACKFILL_ELECTION_ID}/index"
    end
  end
end
