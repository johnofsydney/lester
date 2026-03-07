class AuAecDonations::Donation
  # attr_reader :donation_amount, :donation_date, :donor_name, :recipient_name

  def initialize(row_hash)
    @row_hash = row_hash
  end

  attr_reader :row_hash

  def amount = row_hash['Amount']
  def date = Date.parse(row_hash['TransactionDate'])
  def donor_name = row_hash['ReturnClientName'].strip
  def recipient_name = row_hash['DonationMadeToName'].strip
  def donor_aec_id = row_hash['ClientFileId']
  def recipient_aec_id = row_hash['DonationMadeToClientFileId']
  def financial_year = row_hash['FinancialYear'].strip
  def return_id = row_hash['ReturnId']
end
