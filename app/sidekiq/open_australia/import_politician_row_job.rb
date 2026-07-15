class OpenAustralia::ImportPoliticianRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1,
    queue: 'low'
  )

  def perform(person_id, house)
    OpenAustralia::ImportPoliticianRow.call(person_id:, house:)
  end
end
