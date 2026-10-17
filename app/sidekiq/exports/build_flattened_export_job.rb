class Exports::BuildFlattenedExportJob
  include Sidekiq::Job

  sidekiq_options queue: :low

  QUANTITY = 500
  DELAY = 5.minutes
  PHASES = %w[people groups compose].freeze

  def perform(phase = 'people')
    case phase
    when 'people'
      refresh_batch(Person, 'people')
    when 'groups'
      refresh_batch(Group, 'groups')
    when 'compose'
      Exports::FlattenedDataset.call
    end
  end

  private

  def refresh_batch(klass, phase)
    klass.cache_stale.order(:id).limit(QUANTITY).each(&:refresh_cached_data!)

    next_phase = klass.cache_stale.exists? ? phase : PHASES[PHASES.index(phase) + 1]
    self.class.perform_in(DELAY, next_phase)
  end
end
