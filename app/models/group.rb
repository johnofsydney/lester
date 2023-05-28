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

  # def first_degree_given_transfers
  #   given_transfers
  # end

  # def first_degree_received_transfers
  #   received_transfers
  # end

  # def first_degree_given_transfer_nodes
  #   # who did this group give to?
  #   first_degree_given_transfers.map(&:taker)
  # end

  # def first_degree_received_transfer_nodes
  #   # who did this group receive from?
  #   first_degree_received_transfers.map(&:giver)
  # end


  # def second_degree_given_transfers
  #   nodes.flat_map(&:given_transfers)
  # end

  # def second_degree_received_transfers
  #   nodes.flat_map(&:received_transfers)
  # end

  # def second_degree_given_transfer_nodes
  #   # of all the nodes who are connected to this group, what are the nodes they gave to?
  #   second_degree_given_transfers.map(&:taker).flatten - [self]
  # end

  # def second_degree_received_transfer_nodes
  #   # of all the nodes who are connected to this group, what are the nodes they received transfers from?
  #   second_degree_received_transfers.map(&:giver).flatten - [self]
  # end


  #   def third_degree_given_transfers
  #   nodes.flat_map(&:second_degree_given_transfers)
  # end

  # def third_degree_received_transfers
  #   nodes.flat_map(&:second_degree_received_transfers)
  # end

  # def third_degree_given_transfer_nodes
  #   # of all the nodes who are connected to this group, what are the nodes they gave to?
  #   third_degree_given_transfers.map(&:taker).flatten - nodes - [self]
  # end

  # def third_degree_received_transfer_nodes
  #   # of all the nodes who are connected to this group, what are the nodes they received transfers from?
  #   third_degree_received_transfers.map(&:giver).flatten - nodes - [self]
  # end




end