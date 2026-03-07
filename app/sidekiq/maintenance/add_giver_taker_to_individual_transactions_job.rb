class AddGiverTakerToIndividualTransactionsJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform
    return if none_remaining?

    IndividualTransaction.where(giver_id: nil).limit(100).find_each do |transaction|
      transfer = transaction.transfer
      next unless transfer

      transaction.update!(giver: transfer.giver) if transfer.giver.present?
      transaction.update!(taker: transfer.taker) if transaction.taker_id.blank? && transfer.taker.present?
    end

    IndividualTransaction.where(taker_id: nil).limit(100).find_each do |transaction|
      transfer = transaction.transfer
      next unless transfer

      transaction.update!(taker: transfer.taker) if transfer.taker.present?
      transaction.update!(giver: transfer.giver) if transaction.giver_id.blank? && transfer.giver.present?
    end

    # Re-run the job if there are still transactions without giver or taker
    AddGiverTakerToIndividualTransactionsJob.perform_in(5.minutes) unless none_remaining?
  end

  def none_remaining?
    IndividualTransaction.where(giver_id: nil).empty? && IndividualTransaction.where(taker_id: nil).empty?
  end
end
