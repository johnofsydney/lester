#  can DELETE after running

class Maintenance::DowncaseAllPeopleNamesJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  BATCH_SIZE = 1000

  def perform(offset = 0)
    people = Person.limit(BATCH_SIZE).offset(offset).to_a
    return if people.empty?

    people.each do |person|
      Maintenance::DowncaseSinglePersonNameJob.perform_async(person.id)
    end

    Maintenance::DowncaseAllPeopleNamesJob.perform_in(10.seconds, offset + BATCH_SIZE)
  end
end
