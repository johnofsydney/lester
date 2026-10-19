class Cache::RefreshCachedDataJob
  include Sidekiq::Job

  sidekiq_options queue: :low

  def perform(class_name, id)
    record = class_name.constantize.find_by(id: id)
    return unless record

    record.cached_summary = record.to_h
    record.cached_summary_timestamp = Time.zone.now
    record.save!

    key = "#{class_name.underscore}/#{record.name}_#{id}.json"
    Exports::UploadKeyContentsJob.perform_async(key, record.cached_summary.to_json)
  rescue StandardError => e
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    Rails.logger.error "Error building cached data for #{class_name} ID #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
