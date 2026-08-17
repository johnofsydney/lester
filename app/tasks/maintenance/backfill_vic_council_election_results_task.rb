# Backfills the one prior VIC council election cycle confirmed reachable in the current
# vec.vic.gov.au site structure (see
# notes/2026-08-15-council-ingestion-production-readiness-goal-2.md for the live research behind
# that scope decision). Run from /maintenance_tasks -- order relative to the current-cycle import
# no longer matters (see notes/2026-08-17-council-dates-deferred-to-interpretation.md).
module Maintenance
  class BackfillVicCouncilElectionResultsTask < MaintenanceTasks::Task
    BACKFILL_ELECTION_YEAR = Councils::Vic::Elections::ALL.first[:year]

    def collection
      @collection ||= fetch_councils
    end
    delegate :count, to: :collection

    # Enqueues rather than calling ImportCouncilResultRowJob's #perform directly, so a single
    # council's failure retries and eventually dead-letters via Sidekiq's own machinery (which
    # sidekiq_options(retry: 3, ...) relies on) instead of raising straight out of #process and
    # halting the whole task run. Spaced the same way as the normal fan-out
    # (Councils::Vic::IngestElectionResultsJob) so ~76 near-instant enqueues don't hammer VEC
    # once Sidekiq's 5 concurrent workers pick them up.
    def process(council)
      delay = collection.index(council) * Councils::Vic::IngestElectionResultsJob::IMPORT_SPACING
      Councils::Vic::ImportCouncilResultRowJob.perform_in(delay, council[:name], council[:slug], BACKFILL_ELECTION_YEAR)
    end

    private

    def fetch_councils
      page = Councils::PageDownloader.call(index_url)
      raise "Failed to download VIC council index: #{index_url}" if page.blank?

      councils = Councils::Vic::ResultsIndexParser.call(page)
      raise "No councils found on VIC council index: #{index_url}" if councils.blank?

      councils
    end

    def index_url
      "https://www.vec.vic.gov.au/results/council-election-results/#{BACKFILL_ELECTION_YEAR}-council-election-results"
    end
  end
end
