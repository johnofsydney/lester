class AuAecDonations::Donation
  # attr_reader :donation_amount, :donation_date, :donor_name, :recipient_name

  def initialize(row_hash)
    @row_hash = row_hash
  end

  attr_reader :row_hash

  def amount = row_hash['Amount']
  def donor_name = row_hash['ReturnClientName'].strip
  def recipient_name = row_hash['DonationMadeToName'].strip
  def donor_aec_id = row_hash['ClientFileId']
  def recipient_aec_id = row_hash['DonationMadeToClientFileId']
  def financial_year = row_hash['FinancialYear'].strip
  def return_id = row_hash['ReturnId']
  def registration_code = row_hash['RegistrationCode']
  def description = "Donation of $#{amount.to_f} from #{donor_name} to #{recipient_name} on #{date}"

  def date
    return Date.parse(row_hash['TransactionDate']) if row_hash['TransactionDate'].present?

    # if TransactionDate is missing, try to infer it from the financial year (use the last day of the financial year)
    if financial_year.present?
      if financial_year.match?(/^\d{4}-\d{2}$/)
        start_year = financial_year[0..3].to_i
        end_year_suffix = financial_year[5..6]
        end_year = end_year_suffix.to_i >= 50 ? (1900 + end_year_suffix.to_i) : (2000 + end_year_suffix.to_i)
        return Date.new(end_year, 6, 30) # use June 30 as the last day of the financial year
      elsif financial_year.match?(/^\d{4}-\d{4}$/)
        start_year = financial_year[0..3].to_i
        end_year = financial_year[5..8].to_i
        return Date.new(end_year, 6, 30) # use June 30 as the last day of the financial year
      end
    end

    raise ArgumentError, "Unable to determine date for donation: #{row_hash.inspect}"
  end

  def donor_name
    if row_hash['ReturnClientName'].present? && row_hash['ReturnClientName'].match?(/unknown/i)
      row_hash['CurrentClientName'].strip
    else
      row_hash['ReturnClientName'].strip
    end
  end
end
