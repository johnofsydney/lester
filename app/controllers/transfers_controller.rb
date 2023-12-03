class TransfersController < ApplicationController
  before_action :set_transfer, only: %i[ show edit update destroy ]
  layout -> { ApplicationLayout }

  def index
    render Transfers::IndexView.new(transfers: Transfer.all)
  end

  def show
    render Transfers::ShowView.new(transfer: @transfer)
  end

  def new
  end

  def edit
  end

  def create
  end

  def update
  end

  private

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

end
