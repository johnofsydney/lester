module TransferMethods
  extend ActiveSupport::Concern

  included do
    # depth is the number of degrees of separation from the invoking node, 0 being the invoking node itself
    def consolidated_transfers(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, caller: self)
      p "{counter: #{counter}, depth: #{depth}, results.count: #{results.count}, visited_nodes.count: #{visited_nodes.count}, queue.count: #{queue.count}, queue: #{queue.map{|node| node.name} }, caller: #{caller.name}}  }"

      queue.each do |node|
        visited_nodes << node # store the current node as visited

        # TODO: are the transfer methods in Person and Group helpful or harmful?
        Transfer.where(giver: node).includes([:giver, :taker]).each do |transfer|
          results << transfer_struct(transfer:, depth: counter, direction: 'outgoing')
        end

        next unless node.class == Group
        Transfer.where(taker: node).includes([:giver, :taker]).each do |transfer|
          results << transfer_struct(transfer:, depth: counter, direction: 'incoming')
        end
      end

      return results if depth == 0

      depth -= 1
      counter += 1


      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue
      queue = queue.map do |node|
        node.nodes # where there is an overlap
      end.flatten.uniq - visited_nodes
      # queue = queue.map(&:nodes).flatten.uniq - visited_nodes

      consolidated_transfers(depth:, results:, visited_nodes:, queue:, counter:)
    end

    def consolidated_descendents(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, visited_memberships: {})
      p "{results.count: #{results.count}, visited_nodes.count: #{visited_nodes.count}, queue.count: #{queue.count}, counter: #{counter}, depth: #{depth}}  }"
      p "visited_memberships: #{visited_memberships}"
      current_depth_memberships = []
      queue.each do |node|

        visited_nodes << node # store the current node as visited
        current_depth_memberships << node.memberships.to_a

        results << descendent_struct(node:, depth:, counter:)
      end

      return results if depth == 0
      # return results.reject { |descendent| descendent.depth.zero? } if depth == 0


      visited_memberships[counter] = current_depth_memberships.flatten
      visited_memberships[:ids] ||= []
      visited_memberships[:ids] << current_depth_memberships.flatten
      visited_memberships[:ids] = visited_memberships[:ids].flatten.uniq



      previous_queue = queue
      # memberships = previous_queue.map(&:memberships).flatten.uniq
# binding.pry

      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue
      # something something overlapping memberships (for people?)
      # queue = queue.map(&:nodes).flatten.uniq - visited_nodes
      queue = queue.map do |node|
        # node.nodes.filter{|next_node| overlaps?(next_node, visited_memberships)} # where there is an overlap

        # binding.pry
        node.nodes.filter do |next_node|
          if counter < 2
            true
          else
            if next_node.class == Person && next_node.id == 34
              # binding.pry
            end
            next_node_memberships = next_node.memberships
            result = false if next_node_memberships.empty?


            next_node_overlapping_memberships = next_node_memberships.map { |membership| membership.overlapping }

            # binding.pry
            if next_node_overlapping_memberships
              # binding.pry if next_node.id == 34
              next_node_overlapping_memberships.flatten.pluck(:id) & visited_memberships[:ids].pluck(:id) == [] ? false : true
            else
              false
            end


            # result
          end
        end
      end.flatten.uniq - visited_nodes

      depth -= 1
      counter += 1
      consolidated_descendents(depth:, results:, visited_nodes:, queue:, counter:, visited_memberships:)
    end

    private

    def overlaps(node, visited_memberships)
      memberships = node.memberships
      memberships.any? do |membership|
        visited_memberships.any? do |depth, memberships|
          memberships.include?(membership)
        end
      end
    end

    def transfer_struct(transfer:, depth:, direction:)
      OpenStruct.new(
        id: transfer.id,
        giver: transfer.giver,
        taker: transfer.taker,
        amount: transfer.amount,
        effective_date: transfer.effective_date,
        depth:,
        direction:
      )
    end

    def descendent_struct(node:, depth:, counter:)
      OpenStruct.new(
        id: node.id,
        name: node.name,
        depth: counter
      )
    end
  end
end