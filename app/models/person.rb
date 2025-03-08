class Person < ApplicationRecord
  include PgSearch::Model
  include ActionView::Helpers::NumberHelper
  multisearchable against: [:name]

  include TransferMethods
  include NodeMethods

  has_many :memberships, as: :member, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :positions, through: :memberships

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

  def summary
    body = <<~SUMMARY.strip
      🔍 #{name}

      👥 Member of #{number_of_groups}
      🔗 Directly connected to #{number_of_direct_contacts} in our database.

      💰 Money Tracker:
      ➡️ Direct transfers: #{direct_transfers}.
      📡 One degree separation: #{first_degree_transfers}
    SUMMARY


    call_to_action = "\n\n" + "See more: https://jointhedots.au/people/#{id}"
    body += call_to_action if (body.length + call_to_action.length) < 300
    aus_pol_tag = "\n\n" + "#AusPol"
    body += aus_pol_tag if (body.length + aus_pol_tag.length) < 300
    name_to_tag = ' #' + name.downcase.gsub(' ', '_')
    body += name_to_tag if (body.length + name_to_tag.length) < 300
    final_sign_off = ' #follow_the_money'
    body += final_sign_off if (body.length + final_sign_off.length) < 300

    body.strip
  end

  private

  def direct_friendships
    # PEOPLE, with whom this person has a direct relationship, ie they are both part of the same group.
    # The group must be <= MAX_GROUP_SIZE_TO_FOLLOW, otherwise the relationship is too weak to be considered direct.
    # That constant is used in the BuildQueue service.
    consolidated_descendents_depth(2).filter{|descendent| descendent.klass == 'Person' && descendent.depth == 2}
  end

  def direct_transfers
    transfers = OpenStruct.new(
      in: incoming_transfers.sum(:amount),
      out: outgoing_transfers.sum(:amount)
    )

    return 'None' if transfers.in.zero? && transfers.out.zero?
    return "Incoming: #{number_to_currency(transfers.in, precision: 0)}" if transfers.out.zero?
    return "Outgoing: #{number_to_currency(transfers.out, precision: 0)}" if transfers.in.zero?

    "Incoming: #{number_to_currency(transfers.in, precision: 0)}, Outgoing: #{number_to_currency(transfers.out, precision: 0)}"
  end

  def first_degree_transfers
    transfers = consolidated_transfers(depth: 1).filter { |transfer| transfer.depth == 1 }
    incoming_transfers = transfers.filter { |transfer| transfer.direction == 'incoming' }
    outgoing_transfers = transfers.filter { |transfer| transfer.direction == 'outgoing' }
    OpenStruct.new(
      in: number_to_currency(incoming_transfers.sum(&:amount), precision: 0),
      out: number_to_currency(outgoing_transfers.sum(&:amount), precision: 0)
    )

    return 'None' if incoming_transfers.empty? && outgoing_transfers.empty?
    return "Incoming: #{number_to_currency(incoming_transfers.sum(&:amount), precision: 0)}" if outgoing_transfers.empty?
    return "Outgoing: #{number_to_currency(outgoing_transfers.sum(&:amount), precision: 0)}" if incoming_transfers.empty?

    "Incoming: #{number_to_currency(incoming_transfers.sum(&:amount), precision: 0)}, Outgoing: #{number_to_currency(outgoing_transfers.sum(&:amount), precision: 0)}"
  end

  def number_of_groups
    "#{nodes_count} #{'group'.pluralize(nodes_count)}"
  end

  def number_of_direct_contacts
    "#{direct_friendships.count} #{'person'.pluralize(direct_friendships.count)}"
  end
end
