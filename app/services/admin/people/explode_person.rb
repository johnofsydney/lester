class Admin::People::ExplodePerson
  def self.call(person)
    new(person).call
  end

  def initialize(person)
    @person = person
  end

  attr_reader :person

  def call
    membership_ids = []

    Membership.transaction do
      Membership.where(member: person).find_each do |membership|
        new_person = Person.create!(name: unique_name_for(membership))
        membership.update!(member: new_person)

        membership_ids << membership.id
      end

      person.destroy!
      membership.group.update(cached_data: {})
      BuildGroupCachedDataJob.perform_async(membership.group.id)
    end

    membership_ids
  end

  private

  def unique_name_for(membership)
    group_name = membership.group.name
    last_position = membership.last_position&.title
    base_name = if last_position
                  "#{person.name} (#{last_position}, #{group_name})"
                else
                  "#{person.name} (#{group_name})"
                end

    return base_name unless Person.where('lower(name) = ?', base_name.downcase).exists?

    "#{base_name} [membership ##{membership.id}]"
  end
end
