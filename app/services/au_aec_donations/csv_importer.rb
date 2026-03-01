# The conductor of the import process for the AU AEC Donations data.
# Reads the CSV file and enqueues a job for each row to be processed.

class AuAecDonations::CsvImporter
  def initialize; end

  def import_donations
    csv = CSV.read(donations_csv_path, headers: true)
    csv.each do |row|
      row_hash = {
        donation_amount: row['Amount'].to_f,
        donation_date: row['Date'].strip,
        donor_name: row['Donor Name']&.strip,
        recipient_name: row['Donation Made To']&.strip,
    }.stringify_keys

      AuAecDonations::ImportDonationRowJob.perform_async(row_hash)
    end
  end

  def donations_csv_path
    @donations_csv_path ||= Rails.root.join('csv_data/Annual_Donations_Made_2025.csv')
  end
end