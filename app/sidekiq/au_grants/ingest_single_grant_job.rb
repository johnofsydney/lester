# Records a single grant award row (already parsed from the XLSX) as an IndividualTransaction

class AuGrants::IngestSingleGrantJob
  include Sidekiq::Job

  sidekiq_options queue: :au_grants,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(row)
    AuGrants::RecordIndividualGrant.call(AuGrants::Release.new(row))
  rescue StandardError => e
    Rails.logger.error "Error ingesting grant #{row['GA ID']}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    raise e
  end
end
