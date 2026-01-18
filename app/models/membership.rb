class Membership < ApplicationRecord
  belongs_to :member, polymorphic: true  # could be a Person or a Group
  belongs_to :group
  has_many :positions, dependent: :destroy

  validates :member_id, :member_type, :group_id, presence: true
  # a member might belong to the same group more than once over time
  # in that case there would be a membership record for each time period
  # eg Wayne Rooney
  # 2002–2004	Everton
  # 2004–2017	Manchester United
  # 2017–2018	Everton

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
end
