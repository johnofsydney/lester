class AuAecDonations::DonationObject::ElectionDonation
  # attr_reader :donation_amount, :donation_date, :donor_name, :recipient_name

  def initialize(row_hash)
    @row_hash = row_hash
  end

  attr_reader :row_hash

  def amount = row_hash['GiftValue']
  def recipient_name = row_hash['ReceiverName'].strip
  def donor_aec_id = row_hash['DonorCode']
  def recipient_aec_id = row_hash['ReceiverClientId']
  def return_id = row_hash['ReturnId']
  def event_id = row_hash['EventId'].to_s
  def event_description = row_hash['EventDescription'].strip
  def description = "Donation of $#{amount.to_f} from #{donor_name} to #{recipient_name} on #{date} for #{event_description}"

  def donation_type
    raise ArgumentError, "Unexpected donation type for row: #{row_hash.inspect}" unless row_hash['EventDescription'].present? && row_hash['EventDescription'].match?(/election/i)

    'federal_election_donation'
  end

  def date = Date.parse(row_hash['GiftDate'])

  def donor_name =row_hash['DonorName'].strip
end
