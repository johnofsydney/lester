class LazyLoadGroupsController < ApplicationController
  def show
    @group = Group.find(params[:id])
    @depth = @group.category? ? 1 : Constants::MAX_SEARCH_DEPTH

    cache_key = "group_#{@group.id}_consolidated_transfers_depth_#{@depth}"
    @group_consolidated_transfers = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
      @group.consolidated_transfers(depth: @depth)
    end
  end
end