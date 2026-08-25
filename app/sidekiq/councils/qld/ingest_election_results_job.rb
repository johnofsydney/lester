require 'sidekiq-scheduler'

# Top-level ingest job for QLD council election results -- discovers every QLD local election
# (general and by-election alike) from the Electoral Commission of Queensland's own election index
# and fans out to Councils::Qld::ImportElectionResultsJob per election, staggered to avoid
# hammering resultsdata.elections.qld.gov.au. Unlike NSW/VIC there is no separate backfill or
# by-election job -- a re-run of this job picks up newly-declared by-elections automatically, since
# they simply appear as new entries in the live elections index.
class Councils::Qld::IngestElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  IMPORT_SPACING = 5.seconds

  def perform
    elections = Councils::Qld::Elections.local
    raise 'No QLD local elections found' if elections.blank?

    elections.each_with_index do |election, index|
      Councils::Qld::ImportElectionResultsJob.perform_in(index * IMPORT_SPACING, election[:stub])
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Qld::IngestElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: Councils::Qld::Elections::ELECTIONS_URL, message: e.message)
    raise e
  end
end
