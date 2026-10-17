class Cache::BuildPersonCachedDataJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, lock: :until_executed, on_conflict: :log

  def perform(id)
    person = Person.find_by(id:)
    return unless person

    Rails.logger.info "Building cached data for Person #{person.name} (ID: #{person.id})"

    person.refresh_cached_data!
  end
end
