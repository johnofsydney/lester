# Server middleware, applied to every job: a PermanentIngestError means a retry can't help (a real
# HTTP error status, or a parser finding none of an expected structure), so this kills the job
# immediately instead of letting it burn through Sidekiq's default retry/backoff schedule. Any other
# exception passes through untouched and retries as normal.
class KillPermanentIngestErrorsMiddleware
  include Sidekiq::ServerMiddleware

  def call(_job_instance, _job_payload, _queue)
    yield
  rescue PermanentIngestError => e
    raise Sidekiq::JobRetry::Skip, e.message
  end
end
