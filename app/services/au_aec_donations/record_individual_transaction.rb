class ValidationError < StandardError; end

class AuAecDonations::RecordIndividualTransaction
  def self.call(row_hash)
    new(row_hash).call
  end

  def initialize(row_hash)
    @row_hash = row_hash
  end

  attr_reader :row_hash

  def donation
    @donation ||= if row_hash['EventDescription'].present? && row_hash['EventDescription'].match?(/referendum/i)
      AuAecDonations::DonationObject::ReferendumDonation.new(row_hash)
    elsif row_hash['EventDescription'].present? && row_hash['EventDescription'].match?(/election/i)
      AuAecDonations::DonationObject::ElectionDonation.new(row_hash)
    elsif row_hash['ViewName'] == 'Annual Donor Donation Made'
      AuAecDonations::DonationObject::AnnualDonation.new(row_hash)
    else
      raise "Unable to determine donation type for row: #{row_hash.inspect}"
    end
  end

  def call
    raise ValidationError, "Invalid transaction data: #{donation.inspect}" unless valid?

    # OK instantiate giver and taker so that they are available for the transfer record creation
    donor
    recipient

    IndividualTransaction.find_or_create_by(
      giver: donor,
      taker: recipient,
      transfer:,
      amount: donation.amount.to_f,
      effective_date: donation.date,
      transaction_type: 'donation',
      evidence:,
      description: donation.description,
      fine_grained_transaction_category:,
      registration_code: donation.registration_code,
      return_id: donation.return_id
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
      effective_date: Dates::FinancialYear.new(donation.date).last_day,
      transfer_type: 'donations',
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
    FineGrainedTransactionCategory.find_or_create_by!(name: 'au_aec_donation.annual')
  end
end
