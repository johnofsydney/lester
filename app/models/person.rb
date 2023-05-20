class Person < ApplicationRecord
  has_many :memberships
  has_many :groups, through: :memberships
  has_many :group_memberships, through: :groups, source: :memberships
  has_many :group_people, -> { distinct }, through: :group_memberships, source: :person, class_name: 'Person'

  has_many :transfers, as: :giver

  def friends
    group_people.where.not(id: self.id)
  end
end