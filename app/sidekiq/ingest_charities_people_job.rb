# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestCharitiesPeopleJob
  include Sidekiq::Job

  def perform
    batch_size = 50
    one_year_ago = 1.year.ago

    charity_groups = Group.find_by(name: "Charities").groups.where.not(business_number: [nil, ''])
    groups_to_fetch = charity_groups.where(last_refreshed: nil)
                                    .or(charity_groups.where(last_refreshed: ..one_year_ago))
                                    .limit(batch_size)

    groups_to_fetch.each do |group|
      AcncCharities::FetchSingleCharityPeople.perform(group)
    end

    # Re-enqueue itself until fully done
    self.class.perform_async

  rescue StandardError => e
    Rails.logger.error "Error processing charities people: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
