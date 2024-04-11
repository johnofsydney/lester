class NodeLinker
  def initialize(start_node, end_node, include_looser_nodes: false)
    @start_node = start_node
    @end_node = end_node
    @include_looser_nodes = include_looser_nodes
  end

  def find_links
    queue = [[@start_node, []]]
    visited = []

    until queue.empty? # uses until loop rather than recursion
      current_node, path = queue.shift
      visited << current_node

      if (current_node.class == @end_node.class) && (current_node.id == @end_node.id)
        return path + [current_node]
      end

      current_node.nodes(include_looser_nodes: @include_looser_nodes).each do |node|
        unless visited.include?(node)
          queue << [node, path + [current_node]]
        end
      end
    end

    return nil
  end

  def summarize_links
    path = find_links
    return nil if path.nil?

    summary = []
    path.each_with_index do |node, index|
      if index == 0
        summary << node.name
      else
        previous_node = path[index - 1]

        node_type = node.is_a?(Group) ? 'Group' : 'Person'
        previous_node_type = previous_node.is_a?(Group) ? 'Group' : 'Person'

        membership = Membership.find_by(member_id: previous_node.id, member_type: previous_node_type, group: node) || Membership.find_by(member_id: node.id, member_type: node_type, group: previous_node)

        transfer = Transfer.find_by(giver: previous_node, taker: node) || Transfer.find_by(giver: node, taker: previous_node)

        if membership
          is_or_was = if membership.end_date.nil?
                        'is'
                      elsif membership.end_date < Time.now.to_date
                        'was'
                      else
                        'was'
                      end
          has_or_had = if membership.end_date.nil?
                        'has'
                      elsif membership.end_date < Time.now.to_date
                        'had'
                      else
                        'had'
                      end
            member_or_title = membership&.positions&.last&.title || 'member'

          if previous_node_type == 'Group' && node_type == 'Group'
            summary << "#{is_or_was} affiliated to "
          elsif previous_node_type == 'Group' && node_type == 'Person'
            summary << "that #{has_or_had} a #{member_or_title}: "
          elsif previous_node_type == 'Person' && node_type == 'Group'
            summary << "who #{is_or_was} a #{member_or_title} of "
          end

        elsif transfer
          summary << "=> transfer #{transfer.transfer_type} of $#{transfer.amount} =>"
        end

        summary << node.name
      end
    end

    return summary
  end

  def membership
  end
end