module NodeMethods
  extend ActiveSupport::Concern

  included do
    CACHE_DURATION = 10.seconds

    store_accessor :cached_data, [
      :nodes_count,
      :nodes_count_timestamp,
      :consolidated_descendents_depth_4,
      :consolidated_descendents_depth_4_timestamp
    ], prefix: :cached


    def nodes_count
      # TODO jobs
      if refresh_nodes_count_cache?
        self.update(
          cached_nodes_count:nodes.count,
          cached_nodes_count_timestamp:Time.now
        )
      end

      self.cached_nodes_count
    end

    def consolidated_descendents_depth_4
      # return an array of descendents. cached will be used if available

      if refresh_consolidated_descendents_depth_4_cache?
        result = self.consolidated_descendents(depth: 4).map{
          |descendent| configure_descendent(descendent)
        }

        self.update(
          cached_consolidated_descendents_depth_4: result,
          cached_consolidated_descendents_depth_4_timestamp:Time.now
        )
      end

      result = self.reload.cached_consolidated_descendents_depth_4.map{|d| d.symbolize_keys }

      result.map{ |descendent| Descendent.new(
        id: descendent[:id],
        klass: descendent[:klass],
        name: descendent[:name],
        depth: descendent[:depth],
        parent_count: descendent[:descendent_parent_count],
      ) }
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
      !cached_nodes_count.present?
    end

    def nodes_count_cache_expired?
      return true if cached_nodes_count_missing?

      Time.now - Time.parse(self.cached_nodes_count_timestamp) > 1.week
    end

    def refresh_consolidated_descendents_depth_4_cache?
      return true if consolidated_descendents_depth_4_cache_expired?

      cached_consolidated_descendents_depth_4_missing?
    end

    def cached_consolidated_descendents_depth_4_missing?
      !cached_consolidated_descendents_depth_4.present?
    end

    def consolidated_descendents_depth_4_cache_expired?
      return true if cached_consolidated_descendents_depth_4_missing?

      Time.now - Time.parse(self.cached_consolidated_descendents_depth_4_timestamp) > CACHE_DURATION
    end
  end
end