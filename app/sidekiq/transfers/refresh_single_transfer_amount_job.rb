require 'sidekiq-scheduler'

class Transfers::RefreshSingleTransferAmountJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(transfer_id)
    transfer = Transfer.find(transfer_id)
    update_transfer_amount(transfer)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Transfers::RefreshSingleTransferAmountJob: Transfer #{transfer_id} not found: #{e.message}"
    # Don't re-raise - this won't be fixed by retrying
  end

  def update_transfer_amount(transfer)
    amount = transfer.individual_transactions.sum(:amount)
    return if transfer.amount.to_i == amount.to_i

    # as well as updating the amount, set the value_confirmed flag to nil - this transfer is still being updated.
    # Only historical transfers with a confirmed value will be excluded from the Transfers::HandleZeroValueTransfersJob
    transfer.update(amount: amount, data: transfer.data.merge('value_confirmed' => nil))
    Rails.logger.info "Transfers::RefreshSingleTransferAmountJob: Updated Transfer #{transfer.id} amount to #{amount}"
  end
end
