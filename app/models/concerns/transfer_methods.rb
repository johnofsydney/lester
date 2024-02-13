module TransferMethods
  extend ActiveSupport::Concern

  included do
    # depth is the number of degrees of separation from the invoking node, 0 being the invoking node itself
    def consolidated_transfers(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, caller: self, visited_membership_ids: [])
      current_depth_memberships = []

      queue.each do |node|
        visited_nodes << node # store the current node as visited
        current_depth_memberships << node.memberships.to_a

        # TODO: are the transfer methods in Person and Group helpful or harmful?
        Transfer.where(giver: node).includes([:giver, :taker]).each do |transfer|
          results << transfer_struct(transfer:, depth: counter, direction: 'outgoing')
        end

        next unless node.class == Group # TODO - get rid of this, people can accept transfers too (make taker polymorphic as well)
        Transfer.where(taker: node).includes([:giver, :taker]).each do |transfer|
          results << transfer_struct(transfer:, depth: counter, direction: 'incoming')
        end
      end

      return results if depth == 0

      # add current memberships to visited memberships
      visited_membership_ids << current_depth_memberships.flatten.pluck(:id)

      # clean up the visited memberships
      visited_membership_ids = visited_membership_ids.flatten.uniq

      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue if there are overlapping memberships
      queue = BuildQueue.new(queue, visited_membership_ids, visited_nodes, counter).call


      depth -= 1
      counter += 1
      consolidated_transfers(depth:, results:, visited_nodes:, queue:, counter:, visited_membership_ids:)
    end

    def consolidated_descendents(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, visited_membership_ids: [])
      current_depth_memberships = []
      queue.each do |node|

        visited_nodes << node # store the current node as visited
        current_depth_memberships << node.memberships.to_a

        results << descendent_struct(node:, depth:, counter:)
      end

      return results if depth == 0

      # add current memberships to visited memberships
      visited_membership_ids << current_depth_memberships.flatten.pluck(:id)

      # clean up the visited memberships
      visited_membership_ids = visited_membership_ids.flatten.uniq

      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue (if there are overlapping memberships)
      queue = BuildQueue.new(queue, visited_membership_ids, visited_nodes, counter).call

      depth -= 1
      counter += 1
      consolidated_descendents(depth:, results:, visited_nodes:, queue:, counter:, visited_membership_ids:)
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
        depth: counter,
        klass: node.class.to_s,
      )
    end
  end
end