class RecordGroup
  attr_reader :name, :category

  def initialize(name, category = nil)
    @name = MapGroupNames.new(name).call
    @category = !!category
  end

  def self.call(name, category: nil)
    new(name, category).call
  end

  def call
    group = Group.find_or_create_by(name:)
    group.update(category:) if category

    group
  end
end
