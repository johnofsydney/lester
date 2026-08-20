class OpenAustralia::IngestPersonJob
  include Sidekiq::Job
  sidekiq_options lock: :until_executed, on_conflict: :log

  def perform(person_id)
    person = OpenAustralia::IngestPerson.call(person_id:)
    # IngestPerson returns nil when OpenAustralia has no terms for this person_id
    OpenAustralia::Interpretation::RecordMembershipsAndPositions.call(person:) if person
  rescue OpenAustraliaRateLimitError => e
    Rails.logger.error "Rate limited by OpenAustralia::IngestPersonJob: #{e.message} - will retry"
    ApiLog.create(message: e.message)
    raise e
  rescue OpenAustraliaApiError => e
    # The API told us something about this specific request, not a transient failure -- the same
    # request will fail the same way every time, so retrying via Sidekiq is pointless noise.
    Rails.logger.error "Error processing OpenAustralia::IngestPersonJob: #{e.message} - not retrying"
    ApiLog.create(message: e.message)
  rescue StandardError => e
    Rails.logger.error "Error processing OpenAustralia::IngestPersonJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
