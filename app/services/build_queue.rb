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

    expandable_queue.flat_map(&:nodes).uniq - visited_nodes
  end

  def with_parents
    return [] if (queue.empty? || queue.nil?)

    expandable_queue.flat_map do |queue_node|
      queue_node.nodes.map { |next_node| {parent: queue_node, child: next_node} }
    end.uniq
  end

  private

  def expandable_queue
    queue.select { |queue_node| CanAddToQueue.call(queue_node, counter) }
  end
end