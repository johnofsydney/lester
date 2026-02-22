# ARGS: accept two nodes, and determine if the next_node can be added to the queue.
# RETURN: true or false
# LOGIC: Revamping the logic from the can_add_to_queue? method in BuildQueue service, as follows:
# There are thre combinations of node and next_node to consider:
# 1. node is a Person, next_node is a Group:
# 2. node is a Group, next_node is a Group:
# 3. node is a Group, next_node is a Person:

# In the gold class world we could consider only overlapping memberships,
# and we can come back to this later. It's very expensive
# membership.overlapping will show all memberships overlapping with the given membership.

# For now, we know node and next_node are related, this class chooses when to stop following
# for reasons of size etc. Some false positives are acceptable for now.

class CanAddToQueue
  def self.call(node, next_node, counter)
    new(node, next_node, counter).call
  end

  attr_reader :node, :next_node, :counter

  def initialize(node, next_node, counter)
    @node = node
    @next_node = next_node
    @counter = counter
  end

  def call
    return false if next_node.nodes_count.nil?
    return false if next_node.nodes_count > Constants::MAX_NODE_COUNT_TO_FOLLOW
    return false if counter * next_node.nodes_count > Constants::MAX_NODE_COUNT_TO_FOLLOW
    return false if next_node.is_tag?

    true
  end
end