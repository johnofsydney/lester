class BuildQueue
  attr_reader :visited_membership_ids, :queue, :visited_nodes, :counter

  def initialize(queue, visited_membership_ids, visited_nodes, counter)
    @queue = queue
    @visited_membership_ids = visited_membership_ids
    @visited_nodes = visited_nodes
    @counter = counter
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
    if counter < 2
      # if counter is 0 it the current node.
      # if it is 1, give us the next level of nodes without conditions
      true
    elsif next_node.is_a?(Group)
      # if the next_node, linked to node is a Group, then we want to add it to the queue
      # we assume (for now) that affiliated groups are always overlapping; there is no time component to worry about.
      # note that the people who are members of an affiliated group are not necessarily overlapping with any other people / memberships already visited.
      # so we may possibly add several (affiliated) groups to the queue, but not (necessarily) add any of their people.
      true
    else
      next_node_overlapping_membership_ids = next_node.memberships.flat_map { |membership| membership.overlapping }.pluck(:id)

      next_node_overlapping_membership_ids.any? { |id| visited_membership_ids.include?(id) }
    end
  end
end