class AuAecDonations::Downloader::AnnualDonations < AuAecDonations::Downloader::Base
  FIRST_PAGE_PATH = '/AnnualDonor'.freeze
  SECOND_PAGE_PATH = '/AnnualDonor/DonationsMadeRead'.freeze

  def self.call(financial_year)
    new(financial_year).call
  end

  def initialize(financial_year)
    # required for the filter, must be "2023-24" or "1999-2000" format
    raise unless financial_year.is_a?(String) && financial_year.match?(/^\d{4}-(\d{2}|\d{4})$/)

    @financial_year = financial_year
  end

  attr_reader :financial_year

  def donations_made_read_params
    super.merge(filter: "FinancialYear~eq~'#{financial_year}'")
  end

  def first_page_path = FIRST_PAGE_PATH
  def second_page_path = SECOND_PAGE_PATH
end
