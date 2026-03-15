# The conductor class, coordinating the entire service of fetching, parsing and recording ELECTION donations

class AuAecDonations::Ingestor::ElectionDonationsIngestor
  def self.call
    new.call
  end

  def call
    downloaded_donations.each do |donation_data|
      AuAecDonations::ImportDonationRowJob.perform_async(donation_data)
    end
  end

  private

  def downloaded_donations = AuAecDonations::Downloader::ElectionDonations.call
end

