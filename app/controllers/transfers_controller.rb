class TransfersController < ApplicationController
  include Constants

  before_action :set_transfer, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]
  before_action :set_page, only: %i[ index ]

  # layout -> { ApplicationLayout }

  def index
    if params[:duration_start].present?
      duration_start = Date.new(params[:duration_start].to_i, 1, 1)
      session[:duration_start] = duration_start
    elsif session[:duration_start].present?
      duration_start = session[:duration_start]
    else
      duration_start = Date.new(Transfer.financial_years.first, 1, 1)
    end

    if params[:duration_end].present?
      duration_end = Date.new(params[:duration_end].to_i, 12, 31)
      session[:duration_end] = duration_end
    elsif session[:duration_end].present?
      duration_end = session[:duration_end]
    else
      duration_end = Date.new(Transfer.financial_years.last, 12, 31)
    end

    # beware  #                       .limit(per_page)
    transfers = Transfer.where(effective_date: duration_start..duration_end)
                        .order(amount: :desc)
                        .limit(page_size)
                        .offset(paginate_offset)

    pages = (Transfer.where(effective_date: duration_start..duration_end).count.to_f / page_size).ceil

    render Transfers::IndexView.new(transfers:, page: @page, pages: pages, session: session)
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

  def set_page
    @page = (params[:page] || 0).to_i
  end

  def page_size
    return 250

    @page_size ||= Constants::PAGE_LIMIT
  end
end
