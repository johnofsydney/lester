class Donor::RecordDonation
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def self.call(name)
    new(name).call
  end

  def call
    return nil unless name

    if person_or_group == 'person'
      person = Person.find_or_create_by(name: first_name_last_name)
    else
      # maybe some mapping ?
      group = Group.find_or_create_by(name:)
    end
    # TODO: add donation
  end

  def mapping
    {
      'Liberal Party of Australia' => 'The Coalition',
      'Liberal Party of Australia (S.A. Division)' => 'The Coalition',
      'Liberal Party of Australia - Tasmanian Division' => 'The Coalition',
      'Liberal Party of Australia, NSW Division' => 'The Coalition',
      'Liberal National Party of Queensland' => 'The Coalition',
      'Climate 200 Pty Ltd' => 'Climate 200',
      'National Party of Australia - N.S.W.' => 'The Coalition',
      'Australian Labor Party (N.S.W. Branch)' => 'Australian Labor Party',
      'Australian Labor Party (ALP)' => 'Australian Labor Party',
      'Australian Labor Party (Victorian Branch)' => 'Australian Labor Party',
      'Liberal Party of Australia (Victorian Division)' => 'The Coalition',
      'Liberal Party (W.A. Division) Inc' => 'The Coalition',
      'Liberal Democratic Party (QLD Branch)' => 'Liberal Democratic Party',
    }
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
end