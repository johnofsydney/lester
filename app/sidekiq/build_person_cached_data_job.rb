class BuildPersonCachedDataJob
  include Sidekiq::Job

  sidekiq_options queue: :low_concurrency, lock: :until_executed, on_conflict: :log

  def perform(id)
    person = Person.find_by(id:)
    return unless person

    Rails.logger.info "Building cached data for Person #{person.name} (ID: #{person.id})"

    person.cached_summary = person.to_h
    person.cached_summary_timestamp = Time.zone.now
    person.save
  rescue StandardError => e
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    Rails.logger.error "Error building cached data for Person ID #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
