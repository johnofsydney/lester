# The conductor class, coorinating the entire service of fetching, parsing snd recording donations
class AuAecDonations::DonationsIngestor
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

  def downloaded_donations = AuAecDonations::DonationsDownloader.call(financial_year)

  def format_financial_year(current_year)
    current_year ||= Time.current.year - 1
    raise unless current_year.is_a?(Integer) && current_year.to_s.match?(/^\d{4}$/)

    start_year = current_year - 1
    end_year = current_year.to_s[2..3]
    "#{start_year}-#{end_year}"
  end
end

