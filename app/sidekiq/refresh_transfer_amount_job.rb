require 'sidekiq-scheduler'

class RefreshTransferAmountJob
  include Sidekiq::Job

  def perform
    transfer = Transfer.find(transfer_id)
    return if transfer.nil? || transfer.individual_transactions.count.zero?

    amount = IndividualTransaction.where(transfer_id: transfer.id).sum(:amount)

    transfer.update!(amount: amount)
  end
end
