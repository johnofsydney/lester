# # Delete when executed

class Maintenance::DestroyAndRecreateCharityPeopleJob
    include Sidekiq::Job

    sidekiq_options(
      lock: :until_executed,
      on_conflict: :log,
      retry: 1
    )

    def perform
      # remove all people who only belong to a charity
      Person.only_in_charities.destroy_all

      # remove all memberships where the group is a charity subgroup and the member is a person
      Membership.person_in_charity.destroy_all

      # now no one belongs to a charity, run the job and re-ingest all people who belong to charities
      IngestCharitiesDatasetCsvJob.perform_async
    end
end
