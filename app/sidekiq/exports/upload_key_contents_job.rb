class Exports::UploadKeyContentsJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  def perform(key, contents, previous_key = nil)
    Exports::S3Client.upload(key, contents)
    Exports::S3Client.delete(previous_key) if previous_key.present? && previous_key != key
  rescue StandardError => e
    Rails.logger.error "Error uploading node JSON to S3 for key #{key}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
