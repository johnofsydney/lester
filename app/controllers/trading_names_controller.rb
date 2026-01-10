class TradingNamesController < ApplicationController
  def show
    trading_name = TradingName.find(params[:id])
    owner = trading_name.owner

    if owner.is_a?(Person)
      # redirect_to person_path(owner)

      if owner.cache_fresh?
        render People::ShowView.new(person: owner)
      else
        BuildPersonCachedDataJob.perform_async(owner.id)
        render plain: Constants::PLEASE_REFRESH_MESSAGE, status: :ok
      end
    elsif owner.is_a?(Group)
      # redirect_to group_path(owner)

      if owner.cache_fresh?
        render Groups::ShowView.new(group: owner)
      else
        BuildGroupCachedDataJob.perform_async(owner.id)
        render plain: Constants::PLEASE_REFRESH_MESSAGE, status: :ok
      end
    else
      render plain: 'Owner not found', status: :not_found
    end
  end
end
