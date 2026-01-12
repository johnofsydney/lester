class Nodes::Merge
  def self.call(receiver_node:, argument_node:)
    new(receiver_node:, argument_node:).call
  end

  def initialize(receiver_node:, argument_node:)
    @receiver_node = receiver_node
    @argument_node = argument_node
  end

  def call
    raise 'Cannot merge node into itself' if receiver_node == argument_node
    raise 'Cannot merge different types of node' unless receiver_node.class == argument_node.class

    # 1. Move all transfers from argument_node to receiver_node
    # If there are EQUIVALENT transfers (same giver, taker, effective date) for both nodes,
    # we need to merge the individual transactions into one transfer, and delete the duplicate transfer.
    # 2. Move all memberships from argument_node to receiver_node
    # If there are EQUIVALENT memberships (same group, member) for both nodes,
    # the membership from argument_node can simply be deleted rather than moved.
    # 3. Destroy argument_node
    # 4. Clear cached data on receiver_node (and call job to refresh counts etc)
    # 5. Return receiver_node

    handle_transfers
    handle_memberships

    argument_node.destroy!
    receiver_node.reload
    receiver_node.update(cached_data: {})

    handle_refresh_job

    receiver_node
  end

  private

  def handle_transfers
    argument_node.outgoing_transfers.find_each do |transfer|
      if (equivalent = receiver_node.outgoing_transfers.find_by(taker: transfer.taker, effective_date: transfer.effective_date))
        # The argument_node has an outgoing transfer that has an equivalent to already on receiver_node
        # Keep the equivalent transfer, move over individual transactions, recalculate amount, delete the now-empty transfer

        # Move individual transactions across
        transfer.individual_transactions.find_each do |it|
          it.update!(transfer: equivalent)
        end

        # Recalculate amount on equivalent transfer
        total_amount = equivalent.individual_transactions.sum(:amount)
        equivalent.update!(amount: total_amount)

        # Delete the now-empty transfer
        transfer.destroy!
        next
      else
        transfer.update!(giver: receiver_node)
      end
    end

    argument_node.incoming_transfers.find_each do |transfer|
      if (equivalent = receiver_node.incoming_transfers.find_by(giver: transfer.giver, effective_date: transfer.effective_date))
        # The argument_node has an incoming transfer that has an equivalent to already on receiver_node
        # Keep the equivalent transfer, move over individual transactions, recalculate amount, delete the now-empty transfer

        # Move individual transactions across
        transfer.individual_transactions.find_each do |it|
          it.update!(transfer: equivalent)
        end

        # Recalculate amount on equivalent transfer
        total_amount = equivalent.individual_transactions.sum(:amount)
        equivalent.update!(amount: total_amount)

        # Delete the now-empty transfer
        transfer.destroy!
        next
      else
        transfer.update!(taker: receiver_node)
      end
    end
  end

  def handle_memberships
    handle_memberships_as_member
    handle_memberships_as_group
  end

  def handle_memberships_as_member
    Membership.where(member: argument_node).find_each do |membership|
      if Membership.exists?(group: membership.group, member: receiver_node)
        # Equivalent membership already exists on receiver_node, so just delete this one
        membership.destroy!
      else
        membership.update!(member: receiver_node)
      end
    end
  end

  def handle_memberships_as_group
    Membership.where(group: argument_node).find_each do |membership|
      if Membership.exists?(group: receiver_node, member: membership.member)
        # Equivalent membership already exists on receiver_node, so just delete this one
        membership.destroy!
      else
        membership.update!(group: receiver_node)
      end
    end
  end

  def handle_refresh_job
    if receiver_node.is_a?(Group)
      BuildGroupCachedDataJob.perform_async(receiver_node.id)
    elsif receiver_node.is_a?(Person)
      BuildPersonCachedDataJob.perform_async(receiver_node.id)
    end
  end

  attr_reader :receiver_node, :argument_node
end