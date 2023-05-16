class Donor::RecordDonation
  attr_reader :name

  def initialize(name)
    @name = name.strip
  end

  def self.call(name)
    new(name).call
  end

  def call
    return nil unless name

    if person_or_group == 'person'
      Person.find_or_create_by(name: first_name_last_name)
    else
      Group.find_or_create_by(name: mapped_group_name)
    end
  end

  def person_or_group
    return 'group' if name =~ /Pty Ltd/
    return 'group' if name =~ /Limited/
    return 'person' if name =~ /\w+\,\s\w+/

    'group'
  end

  def first_name_last_name
    name.split(',').reverse.join(' ')
  end

  def mapped_group_name
    Group::NAME_MAPPING[name] || name
  end
end