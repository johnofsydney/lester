# The conductor class, coordinating the entire service of fetching, parsing and recording REFERENDUM donations

class AuAecDonations::Ingestor::ReferendumDonationsIngestor
  def self.call
    new.call
  end

  def call
    downloaded_donations.each do |donation_data|
      AuAecDonations::ImportDonationRowJob.perform_async(donation_data)
    end
  end

  private

  def downloaded_donations = AuAecDonations::Downloader::ReferendumDonations.call
end

