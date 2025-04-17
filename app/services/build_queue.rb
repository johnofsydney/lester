class BuildQueue
  MAX_GROUP_SIZE_TO_FOLLOW = 50

  attr_reader :visited_membership_ids, :queue, :visited_nodes, :counter, :transfer

  def initialize(queue, visited_membership_ids, visited_nodes, counter, transfer = nil)
    @queue = queue
    @visited_membership_ids = visited_membership_ids
    @visited_nodes = visited_nodes
    @counter = counter
    @transfer = transfer
  end

  # returns an array of nodes.
  def call
    return [] if (queue.empty? || queue.nil?)

    queue.map do |queue_node|
      queue_node.nodes.filter { |next_node| can_add_to_queue?(queue_node, next_node) }
    end.flatten.uniq - visited_nodes
  end

  def with_parents
    return [] if (queue.empty? || queue.nil?)

    queue.map do |queue_node|
      queue_node.nodes.filter { |next_node| can_add_to_queue?(queue_node, next_node) }
                      .map { |next_node| {parent: queue_node, child: next_node} }
    end.flatten.uniq
  end


  private

  def can_add_to_queue?(node, next_node)
    if counter > 200
      raise "Counter exceeded"
      # TODO: remove
    elsif node.is_a?(Person) && next_node.is_a?(Group)
      # Don't add the group to the queue if it is so big that not all individuals would know each other
      return next_node.memberships.size < MAX_GROUP_SIZE_TO_FOLLOW
    elsif node.is_a?(Group) && next_node.is_a?(Group)
      # generally always follow affiliated groups.
      # but if we are tracking a transfer, we only want to follow the affiliated group if the transfer is within the timeframe of the membership of group 1 and group 2
      transfer_date = transfer&.effective_date
      return true unless transfer_date

      membership = Membership.find_by(member: next_node, group: node) || Membership.find_by(member: node, group: next_node)

      Rails.logger.debug { "membership: #{membership.inspect}" }

      # permament memberships (have no start or end date) are always overlapping
      return true if membership.start_date.nil? && membership.end_date.nil?

      if membership.end_date.nil? # membership has not yet ended
        # if the transfer date is after the start date of the membership, then we want to add it to the queue
        return (transfer_date >= membership.start_date)
      end

      # if the transfer date is within the timeframe of the membership, then we want to add it to the queue
      (membership.start_date..membership.end_date).cover?(transfer_date)
    # else # next_node is a person
    elsif node.is_a?(Group) && next_node.is_a?(Person)
      # Don't add the person to the queue if they are in a group that is too big to follow
      return false if node.memberships.size > MAX_GROUP_SIZE_TO_FOLLOW

      next_memberships_ids = next_node.memberships.pluck(:id) + Membership.where(member: next_node).pluck(:id)
      next_memberships = Membership.where(id: next_memberships_ids)

      next_node_overlapping_membership_ids = next_memberships.flat_map { |membership| membership.overlapping }.pluck(:id)

      next_node_overlapping_membership_ids.any? { |id| visited_membership_ids.include?(id) }
    else
      raise
    end
  end
end