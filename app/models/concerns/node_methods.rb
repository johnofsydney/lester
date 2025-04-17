module NodeMethods
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  included do
    store_accessor :cached_data, [
      :nodes_count,
      :nodes_count_timestamp,
      :consolidated_descendents,
      :consolidated_descendents_timestamp
    ], prefix: :cached


    # STUFF TO DO WITH CACHING
    def nodes_count
      # TODO jobs
      if refresh_nodes_count_cache?
        self.update(
          cached_nodes_count:nodes.count,
          cached_nodes_count_timestamp:Time.zone.now
        )
      end

      self.cached_nodes_count
    end

    def consolidated_descendents_depth(depth)
      if refresh_consolidated_descendents_depth_cache?(depth)
        result = self.consolidated_descendents(depth: depth).map{
          |descendent| configure_descendent(descendent)
        }

        self.update(
          cached_consolidated_descendents: result,
          cached_consolidated_descendents_timestamp:Time.zone.now
        )
      end

      result = self.reload
                   .cached_consolidated_descendents
                   .map{|d| d.symbolize_keys }
                   .filter{|d| d[:depth] <= depth}

      result.map{ |descendent| Descendent.new(
        id: descendent[:id],
        klass: descendent[:klass],
        name: descendent[:name],
        depth: descendent[:depth],
        parent_count: descendent[:descendent_parent_count],
      ) }
    end


    # STUFF TO DO WITH MONEY SUMMARY
    def money_in
      if is_category?
        amount = category_incoming_transfers.sum(:amount)
      else
        amount = incoming_transfers.sum(:amount)
      end

      return unless amount.positive?

      number_to_currency amount, precision: 0
    end

    def money_out
      if is_category?
        amount = category_outgoing_transfers.sum(:amount)
      else
        amount = outgoing_transfers.sum(:amount)
      end
      return unless amount.positive?

      number_to_currency amount, precision: 0
    end

    def is_category?
      is_category?
    end

    private

    def configure_descendent(descendent)
      {
        id: descendent.id,
        klass: descendent.klass,
        name: descendent.name,
        depth: descendent.depth,
        descendent_parent_id: descendent&.parent&.id,
        descendent_parent_count: descendent&.parent&.nodes_count,
      }
    end

    def refresh_nodes_count_cache?
      return true if nodes_count_cache_expired?

      cached_nodes_count_missing?
    end

    def cached_nodes_count_missing?
      cached_nodes_count.blank?
    end

    def nodes_count_cache_expired?
      return true if cached_nodes_count_missing?

      Time.zone.now - Time.zone.parse(self.cached_nodes_count_timestamp) > 1.week
    end

    def refresh_consolidated_descendents_depth_cache?(depth)
      # if the depth has been previouslt exhausted at this depth, return true TODO

      return true if self.cached_consolidated_descendents.blank?

      max_depth = self.cached_consolidated_descendents.map{|d| d['depth']}.max
      return true if max_depth < depth


      Rails.logger.debug { "max_depth: #{max_depth}" }
      Rails.logger.debug { "depth: #{depth}" }
      false
    end
  end
end