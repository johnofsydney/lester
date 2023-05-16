class Party::RecordDonation
  attr_reader :name

  def initialize(name)
    @name = Group::NAME_MAPPING[name.strip] || name.strip
  end

  def self.call(name)
    new(name).call
  end

  def call
    Group.find_or_create_by(name:)
  end
end
