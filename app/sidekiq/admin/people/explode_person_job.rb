class Admin::People::ExplodePersonJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(person_id)
    person = Person.find(person_id)

    Membership.where(member: person).find_each do |membership|
      group_name = membership.group.name
      last_position = membership.last_position&.title
      person_name = person.name

      disambiguated_name = if last_position
                             "#{person_name} (#{last_position}, #{group_name})"
                           else
                             "#{person_name} (#{group_name})"
                           end

      Person.create!(name: disambiguated_name)
    end

    person.destroy
  end
end