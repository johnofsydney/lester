# The point of this module is to provide methods that will support and populate the .to_h method
# both Groups and People are nodes, and can draw on these methods.
# Methods here do not draw on cached data, that is the job of CachedMethods mixin.

module NodeMethods
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  def money_in
    amount = inbound_transfers.sum(:amount)
    return unless amount.positive?

    if amount > 1_000_000
      number_to_currency(number_to_human(amount, precision: 3))
    else
      number_to_currency(amount, precision: 0)
    end
  end

  def inbound_transfers
    @inbound_transfers ||= is_tag? ? tag_incoming_transfers : incoming_transfers
  end

  def money_out
    amount = outbound_transfers.sum(:amount)
    return unless amount.positive?

    if amount > 1_000_000
      number_to_currency(number_to_human(amount, precision: 3))
    else
      number_to_currency(amount, precision: 0)
    end
  end

  def outbound_transfers
    # outbound and inbound are convenience methods working for tag and non tag
    @outbound_transfers ||= is_tag? ? tag_outgoing_transfers : outgoing_transfers
  end

  def is_tag?
    is_tag?
  end

  def to_h
    {
      id:,
      name:,
      is_tag: is_tag?,
      money_in:,
      money_out:,
      direct_connections:, # TODO: Remove from here
      top_six_as_giver: top_six_as_giver.to_h, # used in chartkick graphs # TODO: Remove from here
      top_six_as_taker: top_six_as_taker.to_h, # used in chartkick graphs # TODO: Remove from here
      graph_color: "##{Digest::MD5.hexdigest(name)[0..5]}", # used in chartkick graphs
      consolidated_descendents: consolidated_descendents(depth: 4).map(&:to_h), # used for the network graph
      consolidated_transfers: consolidated_transfers(depth: 2).map(&:to_h), # is this enough - probably
      data_time_range: data_time_range # used in chartkick graphs
    }
  end

  # private

  def all_the_groups
    # sorts the giver or takers by the amount of money they have given or taken (sum)
    # does not consider year
    @all_the_groups ||= begin
      {
        as_giver: outbound_transfers.group(:taker_id, :taker_type)
                                    .sum(:amount)
                                    .transform_keys{ |key| name_for_bar_graph(key) }
                                    .sort_by{|_k, v| v},
        as_taker: inbound_transfers.group(:giver_id, :giver_type)
                                   .sum(:amount)
                                   .transform_keys{ |key| name_for_bar_graph(key) }
                                   .sort_by{|_k, v| v}
      }
    end
  end

  def top_five_as_giver
    all_the_groups[:as_giver].last(5)
  end

  def top_five_as_taker
    all_the_groups[:as_taker].last(5)
  end

  def others_as_giver
    all_the_groups[:as_giver] - top_five_as_giver
  end

  def others_as_taker
    all_the_groups[:as_taker] - top_five_as_taker
  end

  def top_six_as_giver
    sum_others = others_as_giver.sum{|a| a.last}

    if sum_others.zero?
      top_five_as_giver.to_h
    else
      top_five_as_giver.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
    end
  end

  def top_six_as_taker
    sum_others = others_as_taker.sum{|a| a.last}

    if sum_others.zero?
      top_five_as_taker.to_h
    else
      top_five_as_taker.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
    end
  end

  def name_for_bar_graph(key)
    # TODO: refactor out the fetching from  the db. This is inefficient.
    klass = key[1].constantize # key[1] == type, giver_type or taker_type
    instance = klass.find(key[0]) # key[0] == id, giver_id or taker_id
    name = instance.name

    return name if name.length <= 25

    "#{name[0..25]}..."
  end

  # Person: one row per Membership (their full history — a person can rejoin the same Group,
  # e.g. Barnaby Joyce's three separate Parliament stints, and each should show its own dates).
  # Group: one row per distinct connected Person/Group, showing that connection's best Membership
  # (the currently-open one, else the most recently ended) — a Group's member list shouldn't show
  # the same person/sub-group more than once.
  #
  # In both cases we build each row's position from the specific Membership behind that row,
  # rather than re-querying "a" Membership for the node afterwards — re-querying is what silently
  # collapsed every row for the same (person, group) pair onto a single arbitrary Membership.
  def direct_connections
    if is_a?(Person)
      memberships.order(start_date: :desc).includes(:positions, :group).map do |membership|
        node_connection(membership.group, membership.last_position, membership)
      end
    else
      best_person_memberships.map { |membership| node_connection(membership.member, membership.last_position, membership) } +
        best_group_memberships.map { |membership, other_group| node_connection(other_group, membership.last_position, membership) }
    end
  end

  def best_person_memberships
    memberships.where(member_type: 'Person')
               .includes(:positions, :member)
               .group_by(&:member_id)
               .values
               .map { |candidates| candidates.min_by { |m| membership_recency_key(m) } }
  end

  # Group-to-group connections come from two directions: sub-groups that belong to self
  # (self.memberships, self is the group) and parent groups self belongs to (self is the member).
  # Both are grouped by the *other* group's id so a group connected via both directions, or with
  # multiple non-contiguous Memberships in one direction, still gets exactly one row.
  def best_group_memberships
    as_owner = memberships.where(member_type: 'Group').includes(:positions, :member).map { |m| [m, m.member] }
    as_member = Membership.where(member: self, member_type: 'Group').includes(:positions, :group).map { |m| [m, m.group] }

    # `other_group` can be nil for a Membership whose polymorphic member/group reference is
    # orphaned (e.g. the referenced Group was destroyed without cleaning up its memberships).
    (as_owner + as_member)
      .reject { |_membership, other_group| other_group.nil? }
      .group_by { |_membership, other_group| other_group.id }
      .values
      .map { |pairs| pairs.min_by { |membership, _| membership_recency_key(membership) } }
  end

  def membership_recency_key(membership)
    membership.end_date.nil? ? [0, 0] : [1, -membership.end_date.to_time.to_i]
  end

  def node_connection(node, position, membership = nil)
    basic_info = {
      klass: node.class.name,
      id: node.id,
      name: node.name,
      nodes_count: node.nodes_count,
      is_tag: node.is_tag?,
      current: membership.nil? || membership.end_date.nil?
    }

    formatted_position = format_position(position)
    basic_info[:last_position] = formatted_position if formatted_position.present?

    basic_info
  end

  def format_position(position)
    return '' if position&.title.blank?

    result = position.title

    if position.end_date.present? && position.start_date.present?
      if position.end_date == position.start_date
        result += " | (#{position.formatted_start_date})"
      else
        result += " | (#{position.formatted_start_date} - #{position.formatted_end_date})"
      end
    elsif position.start_date.present?
      result += " | (since #{position.formatted_start_date})"
    elsif position.end_date.present?
      result += " | (until #{position.formatted_end_date})"
    end

    result
  end

  def merge_into(replacement_entity)
    merge!(replacement_entity)
  end

  def merge!(other_entity, queue: nil)
    raise 'Cannot merge self into self' if other_entity == self
    raise 'Cannot merge different types' unless other_entity.class == self.class
    raise 'Cannot merge where both entities have business numbers' if both_have_business_number?(other_entity)
    raise 'Cannot merge where both entities have aec_id' if aec_id.present? && other_entity.aec_id.present?
    raise 'Cannot merge where both entities have acnc_id' if acnc_id.present? && other_entity.acnc_id.present?

    Nodes::Merge.call(receiver_node: self, argument_node: other_entity, queue:)
  end

  def ==(other)
    self.class == other.class && self.id == other.id
  end

  def both_have_business_number?(other_entity)
    business_number.present? && other_entity.business_number.present?
  end
end