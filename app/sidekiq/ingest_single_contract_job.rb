# From the AusTender API, ingest a single contract by its ID

class IngestSingleContractJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(contract_id, retry_count = 0)
    AusTender::IngestSingleContract.new(contract_id).perform
  rescue StandardError => e
    Rails.logger.error "Error ingesting Contract #{contract_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    raise e
  rescue TooManyRequests => e
    retry_count += 1
    if retry_count <= 5
      delay = (2 ** retry_count) * 120  # Exponential backoff: 2, 4, 8, 16, 32 minutes
      Rails.logger.warn "Too Many Requests for Contract #{contract_id}. Retrying in #{delay} seconds (attempt #{retry_count}/3)"
      self.class.perform_in(delay, contract_id, retry_count)
    else
      Rails.logger.error "Failed to ingest Contract #{contract_id} after 3 retries due to Too Many Requests: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
