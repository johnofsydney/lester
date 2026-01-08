class TradingNamesController < ApplicationController
  def show
    trading_name = TradingName.find(params[:id])
    owner = trading_name.owner

    if owner.is_a?(Person)
      redirect_to person_path(owner)
    elsif owner.is_a?(Group)
      redirect_to group_path(owner)
    else
      render plain: "Owner not found", status: :not_found
    end
  end
end
