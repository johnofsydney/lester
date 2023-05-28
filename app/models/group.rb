class Group < ApplicationRecord
  include TransferMethods

  has_many :memberships, dependent: :destroy
  has_many :people, through: :memberships

  has_many :affiliations_as_owning_group, class_name: 'Affiliation', foreign_key: 'owning_group_id', dependent: :destroy
  has_many :affiliations_as_sub_group, class_name: 'Affiliation', foreign_key: 'sub_group_id', dependent: :destroy
  has_many :sub_groups, through: :affiliations_as_owning_group, source: :sub_group
  has_many :owning_groups, through: :affiliations_as_sub_group, source: :owning_group

  has_many :given_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver
  has_many :received_transfers, class_name: 'Transfer', foreign_key: 'taker_id'

  def nodes
    [people + affiliated_groups + other_edge_ends].flatten.compact.uniq
  end

  def transfers_in = received_transfers
  def transfers_out = given_transfers

  # private

  def affiliated_groups
    sub_groups + owning_groups
  end

  def other_edge_ends
    # if a connection is not so strong as to be a relationship in the application
    # we can consider it an 'other' edge, so far, these are only transfers
    # at the end of an edge, there is a node,
    # at the end of a given transfer is the taker of that transfer
    # at the end of a received transfer is the giver of that transfer
    given_transfers.map(&:taker) + received_transfers.map(&:giver)
  end
end
