# Decides whether node can be expanded (its own members enumerated for further traversal).
# Does not decide whether node is displayed - see ADR 0012.
class CanAddToQueue
  def self.call(node)
    new(node).call
  end

  attr_reader :node

  def initialize(node)
    @node = node
  end

  def call
    return false if node.nodes_count.nil?

    node.nodes_count <= Constants::MAX_NODES_TO_EXPAND
  end
end
