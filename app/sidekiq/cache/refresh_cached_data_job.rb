class Cache::RefreshCachedDataJob
  include Sidekiq::Job

  sidekiq_options queue: :low, lock: :until_executed, on_conflict: :log

  def perform(klass, id)
    record = klass.constantize.find_by(id: id)
    return unless record

    previous_key = record.cached_export_key
    summary = record.to_h
    key = "#{klass.underscore}/#{record.name}_#{id}.json"

    record.cached_summary = summary
    record.cached_summary_timestamp = Time.zone.now
    record.cached_export_key = key
    record.save!

    Exports::UploadKeyContentsJob.perform_async(key, summary.to_json, previous_key)
  rescue StandardError => e
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    Rails.logger.error "Error building cached data for #{klass} ID #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
