class Person < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:name]

  include TransferMethods

  has_many :memberships, as: :member, dependent: :destroy
  has_many :groups, through: :memberships

  has_many :outgoing_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver
  has_many :incoming_transfers, class_name: 'Transfer', foreign_key: 'taker_id', as: :taker

  accepts_nested_attributes_for :memberships, allow_destroy: true

  def nodes(include_looser_nodes: false)
    unless include_looser_nodes
      return groups
    end


    # this + will still work for relations not just arrays
    [groups + other_edge_ends].flatten.compact.uniq
  end

  def transfers
    OpenStruct.new(
      incoming: Transfer.where(taker: self), # always nil. replace with [] ?,
      outgoing: Transfer.where(giver: self, giver_type: 'Person').order(amount: :desc)
    )
  end

  def other_edge_ends
    outgoing_transfers.map(&:taker)
  end

  def is_category? = false
end
