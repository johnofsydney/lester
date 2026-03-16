# # Delete when executed

# class Maintenance::BackfillAnnualDonationsJob
#   include Sidekiq::Job

#   sidekiq_options(
#     lock: :until_executed,
#     on_conflict: :log,
#     retry: 1
#   )

#   def perform(year = nil)
#     if year.present?
#       # start ingesting one single year
#       AuAecDonations::Ingestor::AnnualDonationsIngestor.call(year)
#     else
#       # This is the entrypoint for a full backfill, which will be triggered manually
#       # and will ingest all years of donations, starting with the oldest, with a delay between each to avoid overwhelming the system

#       IndividualTransaction.where(transaction_type: 'Australian Political Donation').delete_all
#       Transfer.donations.delete_all
#       Transfer.where(transfer_type: 'Australian Political Donations').delete_all
#       Transfer.where(transfer_type: 'donations').delete_all
#       Transfer.where(transfer_type: 'Donation AU 2023 Referendum').delete_all

#       (1999..2025).each_with_index do |year, index|
#         delay = index * 30.seconds + (index % 5).seconds
#         Maintenance::BackfillAnnualDonationsJob.perform_in(delay, year)
#       end
#     end
#   end
# end
