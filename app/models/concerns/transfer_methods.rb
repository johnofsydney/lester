module TransferMethods
  extend ActiveSupport::Concern

  included do
    def first_degree_given_transfers
      given_transfers
    end

    def first_degree_received_transfers
      received_transfers
    end

    def first_degree_given_transfer_nodes
      # who did this person/group give to?
      first_degree_given_transfers.map(&:taker)
    end

    def first_degree_received_transfer_nodes
      # who did this person/group receive from?
      first_degree_received_transfers.map(&:giver)
    end

    def second_degree_given_transfers
      nodes.flat_map(&:given_transfers).flatten.compact.uniq - first_degree_given_transfers - first_degree_received_transfers
    end

    def second_degree_received_transfers
      nodes.flat_map(&:received_transfers).flatten.compact.uniq - first_degree_given_transfers - first_degree_received_transfers
    end

    def second_degree_given_transfer_nodes
      # of all the nodes who are connected to this group, what are the nodes they gave to?
      second_degree_given_transfers.map(&:taker).flatten - [self]
    end

    def second_degree_received_transfer_nodes
      # of all the nodes who are connected to this group, what are the nodes they received transfers from?
      second_degree_received_transfers.map(&:giver).flatten - [self]
    end

    # NEEDS checking!
    def third_degree_given_transfers
      nodes.flat_map(&:second_degree_given_transfers).flatten.compact.uniq - second_degree_given_transfers - second_degree_received_transfers - first_degree_given_transfers - first_degree_received_transfers
    end

    def third_degree_received_transfers
      nodes.flat_map(&:second_degree_received_transfers).flatten.compact.uniq - second_degree_given_transfers - second_degree_received_transfers  - first_degree_given_transfers - first_degree_received_transfers
    end

    def third_degree_given_transfer_nodes
      # of all the nodes who are connected to this group, what are the nodes they gave to?
      third_degree_given_transfers.map(&:taker).flatten - nodes - [self]
    end

    def third_degree_received_transfer_nodes
      # of all the nodes who are connected to this group, what are the nodes they received transfers from?
      third_degree_received_transfers.map(&:giver).flatten - nodes - [self]
    end

    # NEEDS checking!
    def fourth_degree_given_transfers
      nodes.flat_map(&:third_degree_given_transfers).flatten.compact.uniq
    end

    def fourth_degree_received_transfers
      nodes.flat_map(&:third_degree_received_transfers).flatten.compact.uniq
    end

    def fourth_degree_given_transfer_nodes
      fourth_degree_given_transfers.map(&:taker).flatten - nodes - [self] - third_degree_given_transfer_nodes
    end

    def fourth_degree_received_transfer_nodes
      fourth_degree_received_transfers.map(&:giver).flatten - nodes - [self] - third_degree_received_transfer_nodes
    end
  end
end