class ValidationError < StandardError; end

class AuAecDonations::RecordIndividualTransaction
  def self.call(row_hash)
    new(row_hash).call
  end

  def initialize(row_hash)
    @donation = AuAecDonations::Donation.new(row_hash)
  end

  attr_reader :donation

  def call
    raise ValidationError, "Invalid transaction data: #{donation.inspect}" unless valid?

    # OK instantiate giver and taker so that they are available for the transfer record creation
    donor
    recipient

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
    [donation.donor_name, donation.recipient_name, donation.date, donation.amount].all?(&:present?)
  end

  def transfer
    @transfer ||= RecordTransfer.call(
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
    @donor ||= RecordPersonOrGroup.call(donation.donor_name, mapper:, aec_id: donation.donor_aec_id)
  end

  def recipient
    @recipient ||= RecordPersonOrGroup.call(donation.recipient_name, mapper:, aec_id: donation.recipient_aec_id)
  end

  def mapper
    ::MapGroupNamesAecDonations.new
  end

  def fine_grained_transaction_category
    FineGrainedTransactionCategory.find_or_create_by!(name: 'Australian Political Donation')
  end

  def effective_date
    donation.date
  end

  def amount
    donation.amount.to_f
  end

  def description
    "Donation of $#{amount} from #{donation.donor_name} to #{donation.recipient_name} on #{donation.date}"
  end
end