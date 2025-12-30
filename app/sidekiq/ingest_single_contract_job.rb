# From the AusTender API, ingest a single contract by its ID

class IngestSingleContractJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(contract_id)
    AusTender::IngestSingleContract.new(contract_id).perform
  rescue StandardError => e
    Rails.logger.error "Error ingesting Contract #{contract_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    raise e
  end
end
