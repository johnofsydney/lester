#  can DELETE after running

class Maintenance::DowncaseAllNamesJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform
    Group.find_each do |group|
      Maintenance::DowncaseSingleGroupNameJob.perform_async(group.id)
    end

    Person.find_each do |person|
      Maintenance::DowncaseSinglePersonNameJob.perform_async(person.id)
    end
  end
end
