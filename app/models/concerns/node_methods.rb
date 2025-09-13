module NodeMethods
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  included do
    store_accessor :cached_data, [
      :consolidated_descendents,
      :consolidated_descendents_timestamp,
      :summary,
      :summary_timestamp,
    ], prefix: :cached

    # STUFF TO DO WITH CACHING
    def nodes_count
      nodes.count
    end

    def consolidated_descendents_depth(depth)
      # if refresh_consolidated_descendents_depth_cache?(depth)
      #   result = self.consolidated_descendents(depth: depth).map{
      #     |descendent| descendent.to_h
      #   }

      #   self.update(
      #     cached_consolidated_descendents: result,
      #     cached_consolidated_descendents_timestamp:Time.zone.now
      #   )
      # end

      # result = self.reload
      #              .cached_consolidated_descendents
      #              .map{|d| d.symbolize_keys }
      #              .filter{|d| d[:depth] <= depth}

      # result = self.cached_summary['consolidated_descendents']

      # result.map{ |descendent| Descendent.new(
      #   id: descendent['id'],
      #   klass: descendent['klass'],
      #   name: descendent['name'],
      #   depth: descendent['depth'],
      #   parent_count: descendent['descendent_parent_count'],
      # ) }
    end

    # STUFF TO DO WITH MONEY SUMMARY
    def money_in
      amount = inbound_transfers.sum(:amount)
      return unless amount.positive?

      if amount > 1_000_000
        number_to_currency number_to_human(amount), precision: 4
      else
        number_to_currency amount, precision: 0
      end
    end

    def inbound_transfers
      @inbound_transfers ||= is_category? ? category_incoming_transfers : incoming_transfers
    end

    def money_out
      amount = outbound_transfers.sum(:amount)
      return unless amount.positive?

      number_to_currency number_to_human amount, precision: 4
      # number_to_currency amount, precision: 0
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
        direct_connections:,
        transfers_as_taker: transfers_as_taker.map(&:to_h),
        transfers_as_giver: transfers_as_giver.map(&:to_h),
        top_six_as_giver: top_six_as_giver.to_h,
        top_six_as_taker: top_six_as_taker.to_h,
        graph_color: "##{ Digest::MD5.hexdigest(name)[0..5]}",
        consolidated_descendents: consolidated_descendents(depth: 4).map(&:to_h)
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
                                .sort_by{|k, v| v},
          as_taker: inbound_transfers.group(:giver_id, :giver_type)
                                .sum(:amount)
                                .transform_keys{ |key| name_for_bar_graph(key) }
                                .sort_by{|k, v| v}
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
      klass = key[1].constantize # key[1] == type, giver_type or taker_type
      instance = klass.find(key[0]) # key[0] == id, giver_id or taker_id
      name = instance.name

      return name if name.length <= 25

      name[0..25] + '...'
    end

    def direct_connections
      nodes.map do |n|
        {
          klass: n.class.name,
          id: n.id,
          name: n.name,
          nodes_count: n.nodes_count,
          is_category: n.is_category?
        }
      end
    end

    def transfers_as_taker
      inbound_transfers.map do |t|
        t.augment(depth: is_category? ? 1 : 0, direction: 'incoming')
      end
    end

    def transfers_as_giver
      outbound_transfers.map do |t|
        t.augment(depth: is_category? ? 1 : 0, direction: 'outgoing')
      end
    end

    # def configure_descendent(descendent)
    #   {
    #     id: descendent.id,
    #     klass: descendent.klass,
    #     name: descendent.name,
    #     depth: descendent.depth,
    #     descendent_parent_id: descendent&.parent&.id,
    #     descendent_parent_count: descendent&.parent&.nodes_count,
    #   }
    # end

    # def refresh_nodes_count_cache?
    #   return true if nodes_count_cache_expired?

    #   cached_nodes_count_missing?
    # end

    # def cached_nodes_count_missing?
    #   cached_nodes_count.blank?
    # end

    # def nodes_count_cache_expired?
    #   return true if cached_nodes_count_missing?

    #   Time.zone.now - Time.zone.parse(self.cached_nodes_count_timestamp) > 1.week
    # end

    # def refresh_consolidated_descendents_depth_cache?(depth)
    #   return false
    #   # if the depth has been previouslt exhausted at this depth, return true TODO

    #   return true if self.cached_consolidated_descendents.blank?

    #   max_depth = self.cached_consolidated_descendents.map{|d| d['depth']}.max
    #   return true if max_depth < depth

    #   Rails.logger.debug { "max_depth: #{max_depth}" }
    #   Rails.logger.debug { "depth: #{depth}" }
    #   false
    # end
  end
end