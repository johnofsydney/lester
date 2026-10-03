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
    with_parents.map { |pair| pair[:child] }.uniq - visited_nodes
  end

  def with_parents
    @with_parents ||= expandable_queue.flat_map do |queue_node|
      queue_node.nodes.map { |next_node| {parent: queue_node, child: next_node} }
    end.uniq
  end

  private

  # The traversal root (counter 0) always expands; its ceiling is
  # Constants::MAX_NODE_COUNT_FIRST_DEGREE_CONNECTIONS, applied in consolidated_descendents.
  def expandable_queue
    @expandable_queue ||= counter.zero? ? queue : queue.select { |queue_node| CanAddToQueue.call(queue_node) }
  end
end
