# Decides whether node can be expanded (its own members enumerated for further traversal).
# Does not decide whether node is displayed - see ADR 0012.
class CanAddToQueue
  def self.call(node, counter)
    new(node, counter).call
  end

  attr_reader :node, :counter

  def initialize(node, counter)
    @node = node
    @counter = counter
  end

  def call
    # The root node the user asked for always expands; its ceiling is
    # Constants::MAX_NODE_COUNT_FIRST_DEGREE_CONNECTIONS, applied in consolidated_descendents.
    return true if counter.zero?

    return false if node.nodes_count.nil?
    return false if node.nodes_count > Constants::MAX_NODES_TO_EXPAND

    true
  end
end