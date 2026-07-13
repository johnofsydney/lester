class OpenAustralia::BackfillHistoricalPoliticiansJob
  # Run from console with:
  # OpenAustralia::BackfillHistoricalPoliticiansJob.perform_async
  include Sidekiq::Job

  BATCH_SIZE = 500
  UP_TO_ID   = 15_000

  def perform(from_id = 1)
    to_id = [from_id + BATCH_SIZE - 1, UP_TO_ID].min
    OpenAustralia::BackfillHistoricalPoliticians.call(from_id:, to_id:)
    self.class.perform_in(2.minutes, to_id + 1) if to_id < UP_TO_ID
  end
end
