class TransfersController < ApplicationController
  before_action :set_transfer, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  layout -> { ApplicationLayout }

  def index
    transfers = Transfer.order(amount: :desc)
    render Transfers::IndexView.new(transfers:)
  end

  def show
    render Transfers::ShowView.new(transfer: @transfer)
  end

  private

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def transfer_params
    params.require(:transfer).permit(:giver_id, :giver_type, :taker_id, :amount, :evidence, :transfer_type, :effective_date)
  end

end
