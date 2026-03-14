class AuAecDonations::ImportDonationRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(row_hash)
    AuAecDonations::RecordIndividualTransaction.call(row_hash)
  end
end
