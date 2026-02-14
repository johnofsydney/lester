class Category::AddGroupToCategory
  def self.call(category:, group:)
    new(category: category, group: group).call
  end

  def initialize(category:, group:)
    @category = category
    @group = group
  end

  def call
    raise ArgumentError, 'Category must be a category' unless category.is_category?
    return unless valid?

    Membership.find_or_create_by!(group: category, member: group)
  end

  private

  attr_reader :category, :group

  def valid?
    # If the group is already a member of the government department category then DO NOT add it to any other category, as this would be misleading
    if group.memberships.exists?(group: Group.government_department_category)
      Rails.logger.info("Group #{group.id} is a member of the government department category, so it will not be added to category #{category.id}")
      return false
    end

    true
  end
end
