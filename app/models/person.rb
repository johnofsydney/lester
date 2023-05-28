class Person < ApplicationRecord
  include TransferMethods


  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  has_many :given_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver
  def received_transfers = []

  def nodes
    [groups + other_edge_ends].flatten.compact.uniq
  end

  def transfers_in = received_transfers
  def transfers_out = given_transfers

  # private

  def other_edge_ends
    given_transfers.map(&:taker)
  end
end
