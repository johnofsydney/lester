module TransferMethods
  extend ActiveSupport::Concern

  included do
    # depth is the number of degrees of separation from the invoking node, 0 being the invoking node itself
    def consolidated_transfers(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, caller: self, visited_membership_ids: [])
      current_depth_memberships = []

      queue.each do |node|
        # members and affiliate groups.
        return results  if node.name == 'Federal Parliment' # TODO: use or discard

        visited_nodes << node # store the current node as visited
        current_depth_memberships << node.memberships.to_a

        # TODO: are the transfer methods in Person and Group helpful or harmful?
        Transfer.where(giver: node).find_each do |transfer|
          results << transfer.augment(depth: counter, direction: 'outgoing')
        end

        Transfer.where(taker: node).find_each do |transfer|
          results << transfer.augment(depth: counter, direction: 'incoming')
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

    def consolidated_descendents(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, visited_membership_ids: [], transfer: nil, with_parents: [] )

      current_depth_memberships = []
      queue.each do |node|
        # next  if node.nodes.count > 4
        return results  if node.nodes_count > 1500

        visited_nodes << node # store the current node as visited
        current_depth_memberships << node.memberships.to_a

        unless with_parents.empty?
          parent = with_parents.reverse.find{ |element| element[:child] == node }[:parent]
        end

        # Descendent is probably too big and too memory hungry. TODO: refactor
        results << Descendent.new(node: node, depth: counter, parent:)
      end

      return results if depth == 0

      # add current memberships to visited memberships
      visited_membership_ids << current_depth_memberships.flatten.pluck(:id)

      # clean up the visited memberships
      visited_membership_ids = visited_membership_ids.flatten.uniq

      # get the nodes from the current depth. remove the visited nodes. store the rest in the queue (if there are overlapping memberships)
      service = BuildQueue.new(queue, visited_membership_ids, visited_nodes, counter, transfer)
      queue = service.call
      with_parents = service.with_parents

      depth -= 1
      counter += 1
      consolidated_descendents(depth:, results:, visited_nodes:, queue:, counter:, visited_membership_ids:, transfer:, with_parents:)
    end

    def data_time_range
      from_date = all_transfers.order(:effective_date).limit(1).take.effective_date
      to_date =  all_transfers.order(effective_date: :desc).limit(1).take.effective_date

      "#{from_date.year} to #{to_date.year}"
    end

    def category_incoming_transfers
      return Transfer.none unless self.is_category?

      @category_incoming_transfers ||= Transfer.where(taker_type: 'Group', taker_id: [self.groups.pluck(:id)])
                                               .where.not(giver_id: [self.groups.pluck(:id)])
                                               .or(Transfer.where(taker_type: 'Person', taker_id: [self.people.pluck(:id)]))
    end

    def category_outgoing_transfers
      return Transfer.none unless self.is_category?

      group_ids = self.groups.pluck(:id)
      people_ids = self.people.pluck(:id)

      @category_outgoing_transfers ||= Transfer.where(giver_type: 'Group', giver_id: group_ids)
                                               .where.not(taker_id: group_ids)
                                               .or(Transfer.where(giver_type: 'Person', giver_id: people_ids))
    end

    private

    def all_transfers
      @all_transfers ||= if self.is_category?
                            category_outgoing_transfers.or(category_incoming_transfers)
                          else
                            self.incoming_transfers.or(self.outgoing_transfers)
                          end
    end
  end
end