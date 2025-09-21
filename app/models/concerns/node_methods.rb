module NodeMethods
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  included do
    store_accessor :cached_data, [:summary, :summary_timestamp], prefix: :cached

    # STUFF TO DO WITH CACHING
    def nodes_count
      nodes.count
    end

    # STUFF TO DO WITH MONEY SUMMARY
    def money_in
      amount = inbound_transfers.sum(:amount)
      return unless amount.positive?

      if amount > 1_000_000
        number_to_currency(number_to_human(amount, precision: 3))
      else
        number_to_currency(amount, precision: 0)
      end
    end

    def inbound_transfers
      @inbound_transfers ||= is_category? ? category_incoming_transfers : incoming_transfers
    end

    def money_out
      amount = outbound_transfers.sum(:amount)
      return unless amount.positive?

      if amount > 1_000_000
        number_to_currency(number_to_human(amount, precision: 3))
      else
        number_to_currency(amount, precision: 0)
      end
    end

    def outbound_transfers
      # outbound and inbound are convenience methods working for category and non category
      @outbound_transfers ||= is_category? ? category_outgoing_transfers : outgoing_transfers
    end

    def is_category?
      is_category?
    end

    def to_h
      {
        id:,
        name:,
        is_category: is_category?,
        money_in:,
        money_out:,
        nodes_count:,
        direct_connections:,  # TODO: Remove from here
        # transfers_as_taker: transfers_as_taker.map(&:to_h), # used in chartkick graphs
        # transfers_as_giver: transfers_as_giver.map(&:to_h), # used in chartkick graphs
        top_six_as_giver: top_six_as_giver.to_h, # used in chartkick graphs # TODO: Remove from here
        top_six_as_taker: top_six_as_taker.to_h, # used in chartkick graphs # TODO: Remove from here
        graph_color: "##{Digest::MD5.hexdigest(name)[0..5]}", # used in chartkick graphs
        consolidated_descendents: consolidated_descendents(depth: 4).map(&:to_h), # used for the network graph
        consolidated_transfers: consolidated_transfers(depth: 2).map(&:to_h), # is this enough - probably
        data_time_range: data_time_range # used in chartkick graphs
      }
    end

    # private

    def all_the_groups
      # sorts the giver or takers by the amount of money they have given or taken (sum)
      # does not consider year
      @all_the_groups ||= begin
        {
          as_giver: outbound_transfers.group(:taker_id, :taker_type)
                                      .sum(:amount)
                                      .transform_keys{ |key| name_for_bar_graph(key) }
                                      .sort_by{|_k, v| v},
          as_taker: inbound_transfers.group(:giver_id, :giver_type)
                                     .sum(:amount)
                                     .transform_keys{ |key| name_for_bar_graph(key) }
                                     .sort_by{|_k, v| v}
        }
      end
    end

    def top_five_as_giver
      all_the_groups[:as_giver].last(5)
    end

    def top_five_as_taker
      all_the_groups[:as_taker].last(5)
    end

    def others_as_giver
      all_the_groups[:as_giver] - top_five_as_giver
    end

    def others_as_taker
      all_the_groups[:as_taker] - top_five_as_taker
    end

    def top_six_as_giver
      sum_others = others_as_giver.sum{|a| a.last}

      if sum_others.zero?
        top_five_as_giver.to_h
      else
        top_five_as_giver.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
      end
    end

    def top_six_as_taker
      sum_others = others_as_taker.sum{|a| a.last}

      if sum_others.zero?
        top_five_as_taker.to_h
      else
        top_five_as_taker.to_h.merge('Others' => sum_others).sort_by { |_k, value| value }
      end
    end

    def name_for_bar_graph(key)
      # TODO: refactor out the fetching from  the db. This is inefficient.
      klass = key[1].constantize # key[1] == type, giver_type or taker_type
      instance = klass.find(key[0]) # key[0] == id, giver_id or taker_id
      name = instance.name

      return name if name.length <= 25

      "#{name[0..25]}..."
    end

    def direct_connections
      nodes.map do |n|
        last_position = fetch_last_position(n)

        basic_info = {
          klass: n.class.name,
          id: n.id,
          name: n.name,
          nodes_count: n.nodes_count,
          is_category: n.is_category?
        }

        basic_info[:last_position] = last_position if last_position.present?

        basic_info
      end
    end

    # def transfers_as_taker
    #   inbound_transfers.map do |t|
    #     t.augment(depth: is_category? ? 1 : 0, direction: 'incoming')
    #   end
    # end

    # def transfers_as_giver
    #   outbound_transfers.map do |t|
    #     t.augment(depth: is_category? ? 1 : 0, direction: 'outgoing')
    #   end
    # end

    # def direct_transfers
    #   transfers_as_taker + transfers_as_giver
    # end

    def fetch_last_position(node)
      membership = if self.is_a?(Group) && node.is_a?(Person)
                     Membership.find_by(group: self, member: node)
                   elsif self.is_a?(Person) && node.is_a?(Group)
                     Membership.find_by(group: node, member: self)
                   end

      position = membership&.last_position

      return '' unless position

      result = position.title
      return '' unless result

      if position.end_date.present? && position.start_date.present?
        if position.end_date == position.start_date
          result += " | (#{position.formatted_start_date})"
        else
          result += " | (#{position.formatted_start_date} - #{position.formatted_end_date})"
        end
      elsif position.start_date.present?
        result += " | (since #{position.formatted_start_date})"
      elsif position.end_date.present?
        result += " | (until #{position.formatted_end_date})"
      end

      result
    end
  end
end