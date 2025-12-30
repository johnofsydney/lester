require 'sidekiq-scheduler'

class RefreshTransferAmountJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  include Sidekiq::Job

  def perform(transfer_id)
    transfer = Transfer.find(transfer_id)
    return if transfer.nil? || transfer.individual_transactions.count.zero?

    amount = IndividualTransaction.where(transfer_id: transfer.id).sum(:amount)

    transfer.update!(amount: amount)
  end
end
