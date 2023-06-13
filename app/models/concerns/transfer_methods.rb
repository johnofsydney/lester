module TransferMethods
  extend ActiveSupport::Concern

  included do
    # depth is the number of degrees of separation from the invoking node, 0 being the invoking node itself
    def consolidated_transfers(depth: 0, results: [], visited_nodes: [], queue: [self], counter: 0)
      p "{results.count: #{results.count}, visited_nodes.count: #{visited_nodes.count}, queue.count: #{queue.count}, counter: #{counter}, depth: #{depth}}  }"

      queue.each do |node|
        visited_nodes << node # store the current node as visited

        node.transfers.outgoing.each do |transfer|
          results << make_struct(transfer:, depth: counter, direction: 'outgoing')
        end
        node.transfers.incoming.each do |transfer|
          results << make_struct(transfer:, depth: counter, direction: 'incoming')
        end
      end

      return results if depth == 0

      depth -= 1
      counter += 1
      queue = queue.map(&:nodes).flatten.uniq - visited_nodes # get the nodes from the current depth. remove the visited nodes. store the rest in the queue

      consolidated_transfers(depth:, results:, visited_nodes:, queue:, counter:)
    end

    def make_struct(transfer:, depth:, direction:)
      OpenStruct.new(
        giver: transfer.giver,
        taker: transfer.taker,
        amount: transfer.amount,
        effective_date: transfer.effective_date,
        depth:,
        direction:
      )
    end
  end
end