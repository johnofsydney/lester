class TradingNamesController < ApplicationController
  def show
    trading_name = TradingName.find(params[:id])
    owner = trading_name.owner

    if owner.is_a?(Person)
      # redirect_to person_path(owner)

      if owner.cache_fresh?
        groups = Kaminari.paginate_array(owner.cached.affiliated_groups).page(params[:groups_page])
        render People::ShowView.new(person: owner, groups: groups, transfers_page: params[:transfers_page])
      else
        Cache::BuildPersonCachedDataJob.perform_async(owner.id)
        render plain: Constants::PLEASE_REFRESH_MESSAGE, status: :ok
      end
    elsif owner.is_a?(Group)
      # redirect_to group_path(owner)

      if owner.cache_fresh?
        render Groups::ShowView.new(group: owner, transfers_page: params[:transfers_page])
      else
        Cache::BuildGroupCachedDataJob.perform_async(owner.id)
        render plain: Constants::PLEASE_REFRESH_MESSAGE, status: :ok
      end
    else
      render plain: 'Owner not found', status: :not_found
    end
  end
end
