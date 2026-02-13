class AusTender::CategorizeTakerJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform(individual_transaction_id)
    individual_transaction = IndividualTransaction.find_by(id: individual_transaction_id)
    return unless individual_transaction

    AusTender::CategorizeTaker.call(individual_transaction)
  end
end