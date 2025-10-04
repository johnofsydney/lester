class IngestSingleContractJob
  include Sidekiq::Job

  sidekiq_options queue: :low_concurrency, lock: :until_executed, on_conflict: :log

  def perform(contract_id)
    AusTender::IngestSingleContract.new(contract_id).perform

  rescue StandardError => e
    Rails.logger.error "Error ingesting Contract #{contract_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Optionally, you can re-raise the error if you want Sidekiq to retry the job
  end
end
