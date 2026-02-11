require 'sidekiq-scheduler'

class RefreshSingleTransferAmountJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(transfer_id)
    transfer = Transfer.find(transfer_id)
    update_transfer_amount(transfer)
  end

  def update_transfer_amount(transfer)
    amount = transfer.individual_transactions.sum(:amount)
    return if transfer.amount.to_i == amount.to_i

    # as well as updating the amount, set the value_confirmed flag to nil - this transfer is still being updated.
    # Only historical transfers with a confirmed value will be excluded from the HandleZeroValueTransfersJob
    transfer.update(amount: amount, data: transfer.data.merge('value_confirmed' => nil))
    Rails.logger.info "RefreshTransferAmountJob: Updated Transfer #{transfer.id} amount to #{amount}"
  end
end
