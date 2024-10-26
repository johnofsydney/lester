module TransferMethods
  extend ActiveSupport::Concern
  MAX_GROUP_SIZE_TO_FINISH = 15 # TODO: use or discard
  MAX_SIZE_TO_ACCEPT_DONATIONS = 550 # TODO: use or discard

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
          results << transfer_struct(transfer:, depth: counter, direction: 'outgoing')
        end

        Transfer.where(taker: node).find_each do |transfer|
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

    def consolidated_descendents(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0, visited_membership_ids: [], transfer: nil)
      current_depth_memberships = []
      queue.each do |node|
        # next  if node.nodes.count > 4
        return results  if node.nodes.count > 1500

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
      queue = BuildQueue.new(queue, visited_membership_ids, visited_nodes, counter, transfer).call

      depth -= 1
      counter += 1
      consolidated_descendents(depth:, results:, visited_nodes:, queue:, counter:, visited_membership_ids:, transfer:)
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

      @category_outgoing_transfers ||= Transfer.where(giver_type: 'Group', giver_id: [self.groups.pluck(:id)])
                                               .where.not(taker_id: [self.groups.pluck(:id)])
                                               .or(Transfer.where(giver_type: 'Person', giver_id: [self.people.pluck(:id)]))
    end

    private

    def all_transfers
      @all_transfers ||= if self.is_category?
                            category_outgoing_transfers.or(category_incoming_transfers)
                          else
                            self.incoming_transfers.or(self.outgoing_transfers)
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
        depth: counter,
        klass: node.class.to_s,
      )
    end
  end
end