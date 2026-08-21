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
    CanAddToQueue.call(node, next_node, counter)
  end
end