class Membership < ApplicationRecord
  belongs_to :member, polymorphic: true  # could be a Person or a Group
  belongs_to :group
  has_many :positions, dependent: :destroy

  validates :member_type, :presence => true
  validates :group_id, :uniqueness => { :scope => [:member_type, :member_id] }

  # validates :person_id, uniqueness: { scope: :group_id, message: "should have one membership per group" }

  def nodes
    [member, group]
  end

  def overlapping
    # return all the memberships that overlap with this one
    # used in BuildQueue
    # investigate caching

    base = Membership.where.not(id: self.id)
                     .where('end_date IS NULL OR end_date >= ?', self.start_date)
                     .where('start_date IS NULL OR start_date <= ?', self.end_date)

    base.where(group_id: self.group.id)
        .or(base.where(member_id: self.member.id))
  end

  def last_position
    positions.order(start_date: :desc).first
  end

  def self.duplicates
    Membership.group('member_type', 'member_id', 'group_id')
              .having('COUNT(*) > 1')
              .pluck(:member_type, :member_id, :group_id, 'ARRAY_AGG(id)')
  end
end
