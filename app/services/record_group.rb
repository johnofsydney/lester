class RecordGroup


  attr_reader :name

  def initialize(name)
    @name = MapGroupNames.new(name).call
  end

  def self.call(name)
    new(name).call
  end

  def call
    Group.find_or_create_by(name:)
  end
end
