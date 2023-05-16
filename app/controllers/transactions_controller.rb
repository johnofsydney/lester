class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ show edit update destroy ]
  layout -> { ApplicationLayout }

  def index
    @transaction = Transaction.includes(:giver, :taker).all
    render Transactions::IndexView.new(transactions: @transactions)
  end

  def show
    render Transactions::ShowView.new(transaction: @transaction)
  end

  def summary
    @summaries = Transaction.group(:giver_id, :taker_id)
                         .select("donor_id, donee_id, SUM(amount) as total_amount")


    render Donations::SummaryView.new(summaries: @summaries)
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  def edit
  end

  def create
  end


  def update
  end

  def destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def transaction_params
    end
end
