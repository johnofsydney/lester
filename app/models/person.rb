class Person < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  has_many :given_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver

  def received_transfers = []


  def nodes
    groups + other_edge_ends
  end

  def other_edge_ends
    given_transfers.map(&:taker)
  end


  def second_degree_given_transfers
    nodes.flat_map(&:given_transfers)
  end

  def second_degree_received_transfers
    nodes.flat_map(&:received_transfers)
  end
end