class OpenAustralia::IngestPersonJob
  include Sidekiq::Job

  def perform(person_id)
    OpenAustralia::IngestPerson.call(person_id:)
  rescue StandardError => e
    Rails.logger.error "Error processing OpenAustralia::IngestPersonJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
