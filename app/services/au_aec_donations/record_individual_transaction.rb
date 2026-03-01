class ValidationError < StandardError; end

class AuAecDonations::RecordIndividualTransaction
  def self.call(donation)
    new(donation).call
  end

  def initialize(donation)
    @donation = donation
  end

  attr_reader :donation

  def call
    raise ValidationError, "Invalid transaction data: #{donation.inspect}" unless valid?

    individual_transaction = IndividualTransaction.create( # rubocop:disable Lint/UselessAssignment
      giver: donor,
      taker: recipient,
      transfer:,
      amount:,
      effective_date:,
      transaction_type: 'Australian Political Donations',
      evidence:,
      description:,
      fine_grained_transaction_category:
    )

    # wait a moment to allow the lock prevention of running duplicates in quick succession
    RefreshSingleTransferAmountJob.perform_in(5.minutes, transfer.id)
  end

  def valid?
    [donor, recipient, effective_date, amount, transfer].all?(&:present?)
  end

  def transfer
    RecordTransfer.call(
      giver: donor,
      taker: recipient,
      effective_date: Dates::FinancialYear.new(effective_date).last_day,
      transfer_type: 'Australian Political Donations',
      evidence:
    )
  end

  def evidence
    'https://transparency.aec.gov.au/AnnualDonor'
  end


  def donor
    RecordPersonOrGroup.call(donation.donor_name, mapper:)
  end

  def recipient
    RecordPersonOrGroup.call(donation.recipient_name, mapper:)
  end

  def mapper
    ::MapGroupNamesAecDonations.new
  end

  def fine_grained_transaction_category
    FineGrainedTransactionCategory.find_or_create_by!(name: 'Australian Political Donation')
  end

  def effective_date
    # NB the date in the CSV
    # is in American format (MM/DD/YY)
    # has only 2 digits for the year, so we need to handle that
    month, day, year = donation.donation_date.split('/')
    year = "20#{year}" if year.length == 2
    Date.new(year.to_i, month.to_i, day.to_i)
  end

  def amount
    donation.donation_amount.to_f
  end

  def description
    "Donation of $#{amount} from #{donation.donor_name} to #{donation.recipient_name} on #{donation.donation_date}"
  end
end