class Membership < ApplicationRecord
  belongs_to :person
  belongs_to :group

  validates :person_id, uniqueness: { scope: :group_id, message: "should have one membership per group" }

  def nodes
    [person, group]
  end

  def start_date
    super || Date.new(1900, 1, 1)
    # TODO: handle nil value better
  end

  def end_date
    super || Date.new(2100, 1, 1)
    # TODO: handle nil value better
  end

  def overlapping
    # return all the memberships that overlap with this one

    Membership.where(group_id: self.group.id)
              .where.not(id: self.id)
              .where('end_date IS NULL OR end_date >= ?', self.start_date)
              .where('start_date IS NULL OR start_date <= ?', self.end_date)
  end
end

