class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  layout -> { ApplicationLayout }

  # GET /groups or /groups.json
  def index
    groups = Group.where.not(category: true).order(:name)
    render Groups::IndexView.new(groups:)
  end

  # GET /groups/1 or /groups/1.json
  def show
    render Groups::ShowView.new(group: @group, depth: 6)
  end

  # GET /groups/new
  def new
    return unless current_user

    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
    return unless current_user
  end

  # POST /groups or /groups.json
  def create
    return unless current_user

    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        new_membership_params = params.dig(:group, :memberships_attributes, :NEW_RECORD)
        if new_membership_params
          @group.memberships.create(new_membership_params.permit(:person_id, :title, :start_date, :end_date))
        end
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
    return unless current_user

    respond_to do |format|
      if @group.update(group_params)
        new_membership_params = params.dig(:group, :memberships_attributes, :NEW_RECORD)
        if new_membership_params
          @group.memberships.create(new_membership_params.permit(:person_id, :title, :start_date, :end_date))
        end
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
    return unless current_user

    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url, notice: "Group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.require(:group).permit(:name, memberships_attributes: [:id, :title, :start_date, :end_date, :_destroy])
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
