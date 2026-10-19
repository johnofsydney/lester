class Exports::UploadKeyContentsJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  def perform(key, contents)
    Exports::S3Client.upload(key, contents)
  rescue StandardError => e
    Rails.logger.error "Error uploading node JSON to S3 for key #{key}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end