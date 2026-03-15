class AuAecDonations::Downloader::ElectionDonations < AuAecDonations::Downloader::Base
  FIRST_PAGE_PATH = '/Donor'.freeze
  SECOND_PAGE_PATH = '/Donor/DonationsMadeRead'.freeze

  def self.call
    new.call
  end

  def first_page_path = FIRST_PAGE_PATH
  def second_page_path = SECOND_PAGE_PATH
end
