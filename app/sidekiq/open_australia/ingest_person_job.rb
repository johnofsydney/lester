class OpenAustralia::IngestPersonJob
  include Sidekiq::Job

  def perform(person_id)
    person = OpenAustralia::IngestPerson.call(person_id:)
    # IngestPerson returns nil when OpenAustralia has no terms for this person_id
    OpenAustralia::Interpretation::RecordMembershipsAndPositions.call(person:) if person
  rescue StandardError => e
    Rails.logger.error "Error processing OpenAustralia::IngestPersonJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
