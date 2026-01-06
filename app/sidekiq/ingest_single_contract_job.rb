# From the AusTender API, ingest a single contract by its ID

class IngestSingleContractJob
  include Sidekiq::Job

  sidekiq_options queue: :aus_tender_contracts,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(contract_id, retry_count = 0)
    AusTender::IngestSingleContract.call(contract_id)
  rescue ObjectMoved => e
    Rails.logger.error "Error ingesting Contract #{contract_id}: Object Moved"
    Rails.logger.error e.backtrace.join("\n")
    # Do not retry on Object Moved errors
  rescue TooManyRequests => e
    retry_count += 1

    # Mostly this clever retry with back off is less important because
    # when this error is raised we also switch to use Crawlbase service
    # for scraping for one minute

    # don't requeue this job for at least 5 minutes.
    # add jitter to avoid thundering herd - random between 1 and 30 minutes
    # exponential backoff for retries
    # Cloudflare: Client API per user/account token	1200/5 minutes
    if retry_count <= 5
      floor = 300 # 5 minutes
      jitter = rand(60..1800) # 1 to 30 minutes
      multiplier = (2**retry_count) - 1 # Exponential backoff: 1, 2, 4, 8, 16
      delay = (floor + jitter) * multiplier # Add floor, multiplier, and jitter

      Rails.logger.warn "Too Many Requests for Contract #{contract_id}. Retrying in #{delay} seconds (attempt #{retry_count}/5)"
      self.class.perform_in(delay, contract_id, retry_count)
    else
      Rails.logger.error "Failed to ingest Contract #{contract_id} after 5 retries due to Too Many Requests: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # This will fallback to Sidekiq's default retry mechanism
      raise e
    end
  rescue StandardError => e
    Rails.logger.error "Error ingesting Contract #{contract_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    raise e
  end
end
