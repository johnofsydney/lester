# The conductor class, coordinating the entire service of fetching, parsing and recording annual donations
#  Annual donations are predictable (they happen every year) and significant (many donations)
# Start this service with a specific year, or it will default to the previous financial year
# (e.g. if it's currently 2025, it will default to 2024-25)
class AuAecDonations::Annual::DonationsIngestor
  def self.call(year = nil)
    new(year).call
  end

  def initialize(year)
    @financial_year = format_financial_year(year)
  end

  attr_reader :financial_year

  def call
    downloaded_donations.each do |donation_data|
      AuAecDonations::ImportDonationRowJob.perform_async(donation_data)
    end
  end

  private

  def downloaded_donations = AuAecDonations::Downloader::AnnualDonations.call(financial_year)

  def format_financial_year(current_year)
    current_year ||= Time.current.year - 1
    raise unless current_year.is_a?(Integer) && current_year.to_s.match?(/^\d{4}$/)

    start_year = current_year - 1
    end_year = current_year.to_s[2..3]
    "#{start_year}-#{end_year}"
  end
end

