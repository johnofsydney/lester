class Membership < ApplicationRecord
  belongs_to :person
  belongs_to :group

  scope :overlap, lambda { |membership|
      where('start_date < ?', membership.end_date)
        .where('end_date > ?', membership.start_date)
        .where.not(id: membership.id)
        .where(group_id: membership.group_id)
  }

  def overlapping_memberships
    self.class.overlap(self)
  end

  def nodes
    [person, group].flatten.compact.uniq
  end
end