class IngestContractsUrlJob
  include Sidekiq::Job

  sidekiq_options queue: :low_concurrency, lock: :until_executed, on_conflict: :log

  def perform(url)
    TenderIngestor.process_for_url(url: url)
  rescue StandardError => e
    Rails.logger.error "Error processing URL #{url}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Optionally, you can re-raise the error if you want Sidekiq to retry the job
  end
end
