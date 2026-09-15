class TradingNamesController < ApplicationController
  def show
    owner = TradingName.find(params[:id]).owner

    case owner
    when Person then redirect_to person_path(owner)
    when Group then redirect_to group_path(owner)
    else render plain: 'Owner not found', status: :not_found
    end
  end
end
