class TransferDetailsController < ApplicationController
  def show
    @transfer = Transfer.find(params[:id])
  end
end