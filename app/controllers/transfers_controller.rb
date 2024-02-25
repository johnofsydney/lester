class TransfersController < ApplicationController
  before_action :set_transfer, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  layout -> { ApplicationLayout }

  def index
    render Transfers::IndexView.new(transfers: Transfer.includes([:giver, :taker]).all)
    # TODO: make this a search page otherwise it will be too slow. dont bother to paginate
  end

  def show
    render Transfers::ShowView.new(transfer: @transfer)
  end

  def new
    return unless current_user
  end

  def edit
    return unless current_user
  end

  def create
    return unless current_user
  end

  def update
    return unless current_user
    respond_to do |format|
      if @transfer.update(transfer_params)
        format.html { redirect_to transfer_url(@transfer), notice: "Transfer was successfully updated." }
        format.json { render :show, status: :ok, location: @transfer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @transfer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transfers/1 or /transfers/1.json
  def destroy
    return unless current_user
    @transfer.destroy

    respond_to do |format|
      format.html { redirect_to people_url, notice: "Transfer was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def transfer_params
    params.require(:transfer).permit(:giver_id, :giver_type, :taker_id, :amount, :evidence, :transfer_type, :effective_date)
  end

end
