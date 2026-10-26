# Triggers NswStatePoliticians::IngestLcElectionResultsJob in production. LC has no cron entry
# (unlike council elections, which re-run monthly) -- a general election happens once every 4
# years, so this is a manual, occasional trigger rather than a scheduled one. Run from
# /maintenance_tasks, per CODING_STANDARDS.md's "Post-deployment tasks" section: a one-off
# production trigger for a job with no cron goes through a maintenance task, not a raw console
# `.perform_async` call.
#
# Only SG2301 is listed here, not the full NswStatePoliticians::Elections::ALL -- SG1901 is
# currently broken for both LC and LA (older page template, no existing parser handles it; see
# docs/plans/0011-ingest-nsw-state-politicians-design.md and issue #391) and would just dead-letter.
# Add SG1901 here once #391 is resolved.
module Maintenance
  class IngestNswLcElectionResultsTask < MaintenanceTasks::Task
    EVENT_IDS = ['SG2301'].freeze

    attribute :dry_run, :boolean, default: true

    def collection
      EVENT_IDS
    end
    delegate :count, to: :collection

    def process(event_id)
      if dry_run
        Rails.logger.info("[DRY RUN] Would enqueue NswStatePoliticians::IngestLcElectionResultsJob for #{event_id}")
        return
      end

      NswStatePoliticians::IngestLcElectionResultsJob.perform_async(event_id)
    end
  end
end
