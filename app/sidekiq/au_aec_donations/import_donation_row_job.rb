class Donation
  attr_reader :donation_amount, :donation_date, :donor_name, :recipient_name

  def initialize(donation_amount:, donation_date:, donor_name:, recipient_name:)
    @donation_amount = donation_amount
    @donation_date = donation_date
    @donor_name = donor_name
    @recipient_name = recipient_name
  end
end

# The job responsible for processing each row of the AU AEC Donations CSV file.
# It takes the row data, constructs a Donation object, and then
# passes to the service that records the individual transaction in the system.
# NB no casting of the data is done here, it is expected to be done in the service layer.
class AuAecDonations::ImportDonationRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(row_hash)
    donation = Donation.new(**row_hash.symbolize_keys)

    AuAecDonations::RecordIndividualTransaction.call(donation)
  end
end
