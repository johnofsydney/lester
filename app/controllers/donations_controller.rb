class DonationsController < ApplicationController
  before_action :set_donation, only: %i[ show edit update destroy ]
  layout -> { ApplicationLayout }

  # GET /groups or /groups.json
  def index
    @donations = Donation.includes(:donor, :donee).all
    render Donations::IndexView.new(donations: @donations)
  end

  # GET /groups/1 or /groups/1.json
  def show
    render Donations::ShowView.new(donation: @donation)
  end

  def summary
    # @donations = Donation.includes(:donor, :donee).all




    @summaries = Donation.group(:donor_id, :donee_id)
                         .select("donor_id, donee_id, SUM(amount) as total_amount")


    render Donations::SummaryView.new(summaries: @summaries)
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups or /groups.json
  def create
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        format.html { redirect_to group_url(@group), notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    respond_to do |format|
      if update_group(@group)
        format.html { redirect_to group_url(@group), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1 or /groups/1.json
  def destroy
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url, notice: "Group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_donation
      @donation = Donation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.require(:group).permit!
      # params.require(:group).permit(:name)
    end

    def update_group(group)
      people_ids = group_params['people_ids'].select(&:present?).map(&:to_i)

      people_ids.each do |id|
        person = Person.find(id)
        person.groups << group unless person.groups.include?(group)
      end

      group
    end
end
