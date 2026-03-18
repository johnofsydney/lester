class AuAecDonations::DonationObject::ReferendumDonation
  def initialize(row_hash)
    @row_hash = row_hash
  end

  attr_reader :row_hash

  def amount = row_hash['Amount']
  def recipient_name = row_hash['DonationMadeToName'].strip
  def donor_aec_id = row_hash['ClientFileId'].to_s
  def recipient_aec_id = row_hash['DonationMadeToClientFileId'].to_s
  def return_id = row_hash['ReturnId'].to_s
  def event_id = row_hash['EventId'].to_s
  def event_description = row_hash['EventDescription'].strip
  def description = "Donation of $#{amount.to_f} from #{donor_name} to #{recipient_name} on #{date} for #{event_description}"
  def registration_code = row_hash['RegistrationCode']
  def evidence = 'https://transparency.aec.gov.au/ReferendumDonor'
  def transaction_category_key = 'au_aec_donation.referendum'

  def donation_type
    raise ArgumentError, "Unexpected donation type for row: #{row_hash.inspect}" unless row_hash['EventDescription'].present? && row_hash['EventDescription'].match?(/referendum/i)

    'federal_referendum_donation'
  end

  def date = Date.parse(row_hash['TransactionDate'])

  def donor_name
    if row_hash['ReturnClientName'].present? && row_hash['ReturnClientName'].match?(/unknown/i)
      row_hash['CurrentClientName'].strip
    else
      row_hash['ReturnClientName'].strip
    end
  end
end
