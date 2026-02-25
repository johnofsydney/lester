class Tag::AddGroupToTag
  def self.call(tag:, group:)
    new(tag: tag, group: group).call
  end

  def initialize(tag:, group:)
    @tag = tag
    @group = group
  end

  def call
    raise ArgumentError, 'Tag must be a tag' unless tag.is_tag?
    return unless valid?

    Membership.find_or_create_by!(group: tag, member: group)
  end

  private

  attr_reader :tag, :group

  def valid?
    # If the group is already a member of the government department tag then DO NOT add it to any other tag, as this would be misleading
    if Membership.where(group: Group.government_department_tag, member: group).exists?
      Rails.logger.info("Group #{group.id} is a member of the government department tag, so it will not be added to tag #{tag.id}")
      return false
    end

    true
  end
end
