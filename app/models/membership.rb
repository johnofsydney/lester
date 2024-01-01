class Membership < ApplicationRecord
  belongs_to :person
  belongs_to :group

  validates :person_id, uniqueness: { scope: :group_id, message: "should have one membership per group" }

  def nodes
    [person, group]
  end

  def start_date
    super || Date.new(1900, 1, 1)
  end

  def end_date
    super || Date.new(2100, 1, 1)
  end

  def overlapping
    # return all the memberships that overlap with this one
    # that is,
    # - memberships where a person was a member of a group at the same time as this membership
    # - memberships where a group had a member at the same time as this membership

    Membership.where(group_id: self.group.id).or(Membership.where(person_id: self.person.id))
              .where.not(id: self.id)
              # .where('end_date >= ?', self.start_date)
              # .where('start_date <= ?', self.end_date)
              .where('end_date IS NULL OR end_date >= ?', self.start_date)
              .where('start_date IS NULL OR start_date <= ?', self.end_date)
  end
end


# curtin
# -----------start---------end--------------------------------------------
# kevin
# ------------------------------------start--------------------------------------------------------
#mark
# ------------------------------------start-----------------end-----------------------------------------
# john
# ----------------------------------------------------------------------------start-------------------


          # .where('start_date IS NULL OR start_date <= ?', self.end_date)