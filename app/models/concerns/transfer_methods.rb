module TransferMethods
  extend ActiveSupport::Concern

  included do
    # depth is the number of degrees of separation from the invoking node, 0 being the invoking node itself
    def consolidated_transfers(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0)
      p "{results.count: #{results.count}, visited_nodes.count: #{visited_nodes.count}, queue.count: #{queue.count}, counter: #{counter}, depth: #{depth}}  }"

      queue.each do |node|
        visited_nodes << node # store the current node as visited

        # TODO: are the transfer methods in Person and Group helpful or harmful?
        Transfer.where(giver: node).includes([:giver, :taker]).each do |transfer|
          results << transfer_struct(transfer:, depth: counter, direction: 'outgoing')
        end

        Transfer.where(taker: node).includes([:giver, :taker]).each do |transfer|
          results << transfer_struct(transfer:, depth: counter, direction: 'incoming')
        end
      end

      return results if depth == 0

      depth -= 1
      counter += 1
      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue
      queue = queue.map(&:nodes).flatten.uniq - visited_nodes

      consolidated_transfers(depth:, results:, visited_nodes:, queue:, counter:)
    end

    def related_transfers(depth: 6, counter: 0, visited_nodes: [], results: [], visited_memberships: [], queue: self.memberships)
      p "{ results.count: #{results.count}, visited_nodes.count: #{visited_nodes.count}, counter: #{counter}, depth: #{depth}, queue.length: #{queue.length}}"

      queue.each do |membership|
        next if visited_memberships.include?(membership)
        visited_memberships << membership # store the current membership as visited
        date_range = membership.start_date..membership.end_date


        membership.nodes.each do |node|
          p "#{node.name}, membership_id: #{membership.id}, depth: #{counter}"

          next if visited_nodes.include?(node)
          visited_nodes << node # store the current node as visited

          queue << node.memberships
          # queue << node.memberships.where.not(id: membership.id).where(start_date: date_range).or(node.memberships.where.not(id: membership.id).where(end_date: date_range))

          Transfer.where(giver: node, effective_date: date_range).includes([:giver, :taker]).each do |transfer|
            results << transfer_struct(transfer:, depth: counter, direction: 'outgoing')
          end
          Transfer.where(taker: node, effective_date: date_range).includes([:giver, :taker]).each do |transfer|
            results << transfer_struct(transfer:, depth: counter, direction: 'incoming')
          end
        end
      end

      return results if depth == 0

      depth -= 1
      counter += 1
# binding.pry
      queue = queue - visited_memberships
# binding.pry
      related_transfers(depth:, counter:, visited_nodes:, results:, visited_memberships:, queue:)
    end

    def consolidated_descendents(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0)
      p "{results.count: #{results.count}, visited_nodes.count: #{visited_nodes.count}, queue.count: #{queue.count}, counter: #{counter}, depth: #{depth}}  }"

      queue.each do |node|
        visited_nodes << node # store the current node as visited

        results << descendent_struct(node:, depth:, counter:)
      end

      # return results if depth == 0
      return results.reject { |descendent| descendent.depth.zero? } if depth == 0

      depth -= 1
      counter += 1
      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue
      queue = queue.map(&:nodes).flatten.uniq - visited_nodes


      consolidated_descendents(depth:, results:, visited_nodes:, queue:, counter:)
    end

    private

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