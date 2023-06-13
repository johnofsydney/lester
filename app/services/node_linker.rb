class NodeLinker
  def initialize(start_node, end_node, include_looser_nodes: false)
    @start_node = start_node
    @end_node = end_node
    @include_looser_nodes = include_looser_nodes
  end

  def find_links
    queue = [[@start_node, []]]
    visited = []

    until queue.empty?
      current_node, path = queue.shift
      visited << current_node

      # if current_node == @end_node
      if (current_node.class == @end_node.class) && (current_node.id == @end_node.id)
        return path + [current_node]
      end
# binding.pry
      current_node.nodes(include_looser_nodes: @include_looser_nodes).each do |node|
        unless visited.include?(node)
          queue << [node, path + [current_node]]
        end
      end
    end

    return nil
  end

  # def links
  #   find_links.map do |node|
  #     OpenStruct.new(
  #       node_type: node.class.name,
  #       name: node.name
  #     )
  #   end
  # end



  def summarize_links
    path = find_links
    return nil if path.nil?

    summary = []
    path.each_with_index do |node, index|
      if index == 0
        summary << node.name
      else
        previous_node = path[index - 1]
        membership = Membership.find_by(person: previous_node, group: node) || Membership.find_by(person: node, group: previous_node)
        affiliation = Affiliation.find_by(owning_group: previous_node, sub_group: node) || Affiliation.find_by(owning_group: node, sub_group: previous_node)
        transfer = Transfer.find_by(giver: previous_node, taker: node) || Transfer.find_by(giver: node, taker: previous_node)

        if membership
          summary << "=> #{membership.title} =>"
        elsif affiliation
          summary << "=> #{affiliation.description} =>"
        elsif transfer
          summary << "=> transfer #{transfer.transfer_type} of $#{transfer.amount} =>"
        end

        summary << node.name
      end
    end

    return summary
  end
end