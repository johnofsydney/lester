class BuildQueue
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

    queue.map do |node|
      node.nodes.filter { |next_node| can_add_to_queue?(node, next_node) }
    end.flatten.uniq - visited_nodes
  end

  private

  def can_add_to_queue?(node, next_node)
    if counter > 200
      # if counter is 0 it the current node.
      # if it is 1, give us the next level of nodes without conditions
      true
    elsif node.is_a?(Person) && next_node.is_a?(Group)
      # if the next_node, linked to node is a Group, then we want to add it to the queue

      true
    elsif node.is_a?(Group) && next_node.is_a?(Group)
      transfer_date = transfer&.effective_date
      return true unless transfer_date # TODO This works for trnafers. But not general connections...

      membership = Membership.find_by(member: next_node, group: node) || Membership.find_by(member: node, group: next_node)

      p "membership: #{membership.inspect}"

      # permament memberships are always overlapping
      return true if membership.start_date.nil? && membership.end_date.nil?

      if membership.end_date.nil?
        # if the transfer date is after the start date of the membership, then we want to add it to the queue
        transfer_date >= membership.start_date
      end

      # if the transfer date is within the timeframe of the membership, then we want to add it to the queue
      (membership.start_date..membership.end_date).cover?(transfer_date)
    else
      next_memberships_ids = next_node.memberships.pluck(:id) + Membership.where(member: next_node).pluck(:id)
      next_memberships = Membership.where(id: next_memberships_ids)

      next_node_overlapping_membership_ids = next_memberships.flat_map { |membership| membership.overlapping }.pluck(:id)

      next_node_overlapping_membership_ids.any? { |id| visited_membership_ids.include?(id) }

    end
  end
end