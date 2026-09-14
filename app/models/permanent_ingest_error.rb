# Raised by an ingestion job/service when a failure is deterministic -- a real HTTP error status,
# or a parser finding none of an expected structure on a page that downloaded fine -- as opposed to
# a transient network error, where a retry might succeed. Caught by the Sidekiq server middleware
# in config/initializers/sidekiq.rb, which kills the job immediately instead of retrying it.
class PermanentIngestError < StandardError; end
