module TransferMethods
  include Constants

  extend ActiveSupport::Concern

  included do
    # depth is the number of degrees of separation from the invoking node, 0 being the invoking node itself
    def consolidated_transfers(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, visited_membership_ids: [])
      current_depth_memberships = []

      queue.each do |node|
        # members and affiliate groups.
        # TODO - move to a method on Group.
        # If the group is too large for it to make sense to follow transfers through it, skip it, eg Charities
        return []  if node.name == 'Federal Parliament' # TODO: use or discard
        return []  if node.name == 'Charities' # TODO: use or discard
        return [] if results.count > 500

        visited_nodes << node # store the current node as visited
        current_depth_memberships << node.memberships.to_a

        # TODO: are the transfer methods in Person and Group helpful or harmful?
        Transfer.where(giver: node).find_each do |transfer|
          augmented_transfer = transfer.augment(depth: counter, direction: 'outgoing')
          results << augmented_transfer if augmented_transfer
        end

        Transfer.where(taker: node).find_each do |transfer|
          augmented_transfer = transfer.augment(depth: counter, direction: 'incoming')
          results << augmented_transfer if augmented_transfer
        end
      end

      return results if depth.zero? # The end, we've recursed to depth 0
      return results if results.size > Constants::DIRECT_TRANSFERS_COUNT_THRESHOLD # stop recursing. we have enough. don't go any deeper

      # limit the size of the results to avoid overwhelming the system

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

    def consolidated_descendents(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, visited_membership_ids: [], transfer: nil, with_parents: [] )
      current_depth_memberships = []

      # sanity check in case of a large number of nodes on [self] for the first iteration
      # let it return a meaningful collection but not recurse further
      return queue.first.nodes.map { |node| Descendent.new(node:, depth: 0, parent: nil)} if counter.zero? && (queue.first.nodes_count > Constants::MAX_NODE_COUNT_FIRST_DEGREE_CONNECTIONS)

      queue.each do |node|
        visited_nodes << node
        current_depth_memberships << node.memberships.to_a

        parent = nil
        unless with_parents.empty?
          parent_element = with_parents.reverse.find { |element| element[:child] == node }
          parent = parent_element[:parent] if parent_element
        end

        results << Descendent.new(node: node, depth: counter, parent: parent)
      end

      # once depth has reduced to zero, we are done - this is the natural finish
      return results if depth == 0

      # Stop the whole traversal if we've reached the results threshold
      return results if results.size >= Constants::MAX_DESCENDENTS_RESULTS

      # add current memberships to visited memberships
      visited_membership_ids << current_depth_memberships.flatten.pluck(:id)
      visited_membership_ids = visited_membership_ids.flatten.uniq

      # get the nodes for the next depth
      service = BuildQueue.new(queue, visited_membership_ids, visited_nodes, counter, transfer)
      queue = service.call
      with_parents = service.with_parents

      depth -= 1
      counter += 1
      consolidated_descendents(depth:, results:, visited_nodes:, queue:, counter:, visited_membership_ids:, transfer:, with_parents:)
    end

    def data_time_range
      return if all_transfers.empty?

      from_date = all_transfers.order(:effective_date).limit(1).take.effective_date
      to_date =  all_transfers.order(effective_date: :desc).limit(1).take.effective_date

      "#{from_date.year} to #{to_date.year}"
    end

    def tag_incoming_transfers
      return Transfer.none unless self.is_tag?

      @tag_incoming_transfers ||= Transfer.where(taker_type: 'Group', taker_id: [self.groups.pluck(:id)])
                                          .where.not(giver_id: [self.groups.pluck(:id)])
                                          .or(Transfer.where(taker_type: 'Person', taker_id: [self.people.pluck(:id)]))
    end

    def tag_outgoing_transfers
      return Transfer.none unless self.is_tag?

      group_ids = self.groups.pluck(:id)
      people_ids = self.people.pluck(:id)

      @tag_outgoing_transfers ||= Transfer.where(giver_type: 'Group', giver_id: group_ids)
                                          .where.not(taker_id: group_ids)
                                          .or(Transfer.where(giver_type: 'Person', giver_id: people_ids))
    end

    private

    def all_transfers
      @all_transfers ||= if self.is_tag?
                           tag_outgoing_transfers.or(tag_incoming_transfers)
                         else
                           self.incoming_transfers.or(self.outgoing_transfers)
                         end
    end
  end
end