class Person < ApplicationRecord
  include TransferMethods

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :outgoing_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver

  accepts_nested_attributes_for :memberships, allow_destroy: true

  def incoming_transfers = []
  # TODO: this method clashes with transfer.incoming below
  # also results are not consistent between them. Which is correct?

  def nodes(include_looser_nodes: false)
    return self.groups.compact.flatten.uniq unless include_looser_nodes

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
end
