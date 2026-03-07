require 'rails_helper'

describe AuAecDonations::DonationsIngestor do
  before do
    allow(AuAecDonations::DonationsDownloader).to receive(:call).and_return(downloader_result)
    allow(AuAecDonations::ImportDonationRowJob).to receive(:perform_async).and_return(true)
  end

  let(:aec_donor_json) do
    File.read(Rails.root.join('spec/fixtures/aec_annual_donor.json'))
  end
  let(:downloader_result) { JSON.parse(aec_donor_json)['Data'] }

  context 'when a financial year is provided' do
    it 'calls the downloader with the correct financial year' do
      described_class.call(2024)
      expect(AuAecDonations::DonationsDownloader).to have_received(:call).with('2023-24')
    end
  end

  context 'when no financial year is provided' do
    let(:current_year) { Time.current.year }
    let(:expected_financial_year) { "#{current_year - 2}-#{(current_year - 1).to_s[2..3]}" }

    it 'defaults to the previous financial year' do
      described_class.call
      expect(AuAecDonations::DonationsDownloader).to have_received(:call).with(expected_financial_year)
    end
  end

  context 'when the downloader returns results' do
    it 'enqueues a job for each donation' do
      described_class.call(2024)
      expect(AuAecDonations::ImportDonationRowJob).to have_received(:perform_async).exactly(downloader_result.size).times
    end
  end
end