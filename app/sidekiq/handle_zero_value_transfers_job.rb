require 'sidekiq-scheduler'

class HandleZeroValueTransfersJob
  # also handles transfers with negative values,
  # both zero and negative transfer values COULD be data errors that should be fixed by refreshing the amount from the individual transactions
  # If the value is correct, setting the 'value_confirmed' flag to true will prevent the transfer from being included in this job in the future
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform
    transfers = Transfer.government_contracts.where(amount: ..0)
                        .reject { |t| t.data.present? && t.data['value_confirmed'] }

    transfers.each do |transfer|
      RefreshSingleTransferAmountJob.perform_async(transfer.id)
    end
  end
end
