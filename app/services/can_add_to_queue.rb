# Decides whether node can be expanded (its own members enumerated for further traversal).
# Does not decide whether node is displayed - see ADR 0007.
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
    return false if node.nodes_count.nil?
    return false if node.nodes_count > Constants::MAX_NODES_TO_EXPAND

    true
  end
end