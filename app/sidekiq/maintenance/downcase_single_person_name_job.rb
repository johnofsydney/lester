#  can DELETE after running

class Maintenance::DowncaseSinglePersonNameJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform(id)
    person = Person.find(id)

    person.update!(name: person.name.downcase) if person.name.downcase != person.name
  end
end
