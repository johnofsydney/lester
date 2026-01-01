require 'sidekiq-scheduler'

class RefreshTransferAmountJob
  include Sidekiq::Job

  QUANTITY = 2000

  def perform
    transfers_to_refresh.each { |transfer| update_transfer_amount(transfer) }

    # Re-enqueue itself until fully done
    self.class.perform_in(5.minutes) if more_remaining?
  end

  def transfer_ids_to_refresh
    IndividualTransaction.where(created_at: (1.day.ago..)).pluck(:transfer_id).uniq
  end

  def transfers_to_refresh
    Transfer.where(id: transfer_ids_to_refresh).limit(QUANTITY)
  end

  def more_remaining?
    Transfer.where(id: transfer_ids_to_refresh).offset(QUANTITY).exists?
  end

  def update_transfer_amount(transfer)
    amount = transfer.individual_transactions.sum(:amount)
    return if transfer.amount == amount

    transfer.update(amount: amount)
    Rails.logger.info "RefreshTransferAmountJob: Updated Transfer #{transfer.id} amount to #{amount}"
  end
end
