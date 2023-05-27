class Group < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :people, through: :memberships

  has_many :affiliations_as_owning_group, class_name: 'Affiliation', foreign_key: 'owning_group_id', dependent: :destroy
  has_many :affiliations_as_sub_group, class_name: 'Affiliation', foreign_key: 'sub_group_id', dependent: :destroy
  has_many :sub_groups, through: :affiliations_as_owning_group, source: :sub_group

  # belongs_to :owning_group, class_name: 'Group', optional: true
  # TODO - this needs work
  has_many :owning_groups, through: :affiliations_as_sub_group, source: :owning_group

  has_many :given_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver
  has_many :received_transfers, class_name: 'Transfer', foreign_key: 'taker_id'

  def nodes
    people + affiliated_groups + other_edge_ends
  end

  def affiliated_groups
    sub_groups + owning_groups
  end

  def other_edge_ends
    # if a connection is not so strong as to be a relationship in the application
    # we can consider it an 'other' edge, so far, these are only transfers
    given_transfers.map(&:taker) + received_transfers.map(&:giver)
  end

  def second_degree_given_transfers
    nodes.flat_map(&:given_transfers)
  end

  def second_degree_received_transfers
    nodes.flat_map(&:received_transfers)
  end
end