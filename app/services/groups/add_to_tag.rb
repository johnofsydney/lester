class Groups::AddToTag
  def self.call(group_ids:, tag:) = new(group_ids:, tag:).call

  def initialize(group_ids:, tag:)
    @group_ids = group_ids
    @tag = tag
  end

  def call
    Group.where(id: group_ids).find_each do |group|
      Membership.create(
        group: tag,
        member: group,
        member_type: 'Group'
      )
    end
  end

  private

  attr_reader :group_ids, :tag
end
