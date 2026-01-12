require 'sidekiq-scheduler'

class BackfillTransfersAfterMassContractIngestJob
  # run from console with:
  # BackfillTransfersAfterMassContractIngestJob.perform_async
  # Can delete when finished
  include Sidekiq::Job

  QUANTITY = 2_000

  attr_reader :offset

  def perform(offset = 0)
    # ------------------- Overload protection ---------------------
    if queue_overloaded?
      BackfillTransfersAfterMassContractIngestJob.perform_in(5.minutes, offset)
      return
    end

    @offset = offset.to_i

    transfers_to_update.offset(offset).limit(QUANTITY).find_each do |transfer|
      RefreshSingleTransferAmountJob.perform_async(transfer.id)
    end

    # Re-enqueue itself until fully done, increasing the offset each time.
    # The small delay is just to allow the jobs from the loop above to be properly enqueued first.
    self.class.perform_in(30.seconds, offset + QUANTITY) if more_remaining?
  end

  def transfers_to_update
    Transfer.government_contract.order(:id)
  end

  def more_remaining?
    transfers_to_update.offset(offset + QUANTITY).exists?
  end

  def queue_overloaded?
    Sidekiq::Queue.new(:critical).size > 50 ||
      Sidekiq::Queue.new(:default).size > 2_000 ||
      Sidekiq::Queue.new(:low).size > 2_000 ||
      Sidekiq::Queue.new(:aus_tender_contracts).size > 2_000
  end
end
