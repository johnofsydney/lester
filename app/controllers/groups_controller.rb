class GroupsController < ApplicationController
  include Constants

  before_action :set_group, only: %i[ show edit update destroy ]
  before_action :set_page, only: %i[ index ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  layout -> { ApplicationLayout }

  # GET /groups or /groups.json
  def index
    @groups = Rails.cache.fetch("groups_index_#{params[:page]}", expires_in: 12.hours) do

      Group.where.not(category: true).order(:name).limit(per_page).offset(paginate_offset).to_a
    end

    render Groups::IndexView.new(groups: @groups, page: @page)
  end

  # GET /groups/1 or /groups/1.json
  def show
    render Groups::ShowView.new(group: @group, depth: Constants::MAX_SEARCH_DEPTH)
  end

  # GET /groups/new
  def new
    # return unless current_user

    # @group = Group.new
  end

  # GET /groups/1/edit
  def edit
    return unless current_user
  end

  # POST /groups or /groups.json
  def create
    # return unless current_user

    # @group = Group.new(group_params)

    # respond_to do |format|
    #   if @group.save
    #     new_membership_params = params.dig(:group, :memberships_attributes, :NEW_RECORD)
    #     if new_membership_params
    #       @group.memberships.create(new_membership_params.permit(:person_id, :title, :start_date, :end_date))
    #     end
    #     format.html { redirect_to group_url(@group), notice: "Group was successfully created." }
    #     format.json { render :show, status: :created, location: @group }
    #   else
    #     format.html { render :new, status: :unprocessable_entity }
    #     format.json { render json: @group.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    # return unless current_user

    # respond_to do |format|
    #   if @group.update(group_params)
    #     new_membership_params = params.dig(:group, :memberships_attributes, :NEW_RECORD)
    #     if new_membership_params
    #       @group.memberships.create(new_membership_params.permit(:person_id, :title, :start_date, :end_date))
    #     end
    #     format.html { redirect_to group_url(@group), notice: "Group was successfully updated." }
    #     format.json { render :show, status: :ok, location: @group }
    #   else
    #     format.html { render :edit, status: :unprocessable_entity }
    #     format.json { render json: @group.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # DELETE /groups/1 or /groups/1.json
  def destroy
    # return unless current_user

    # @group.destroy

    # respond_to do |format|
    #   format.html { redirect_to groups_url, notice: "Group was successfully destroyed." }
    #   format.json { head :no_content }
    # end
  end

  def affiliated_groups
    @group = Group.find(params[:group_id])
    @page = params[:page].to_i

    render Groups::AffiliatedGroups.new(group: @group)
  end

  def money_summary
    render Common::MoneySummary.new(entity: Group.find(params[:group_id]))
  end

  def group_people
    @group = Group.find(params[:group_id])
    @page = params[:page].to_i
    @pages = (@group.people.count.to_f / page_size).ceil

    @people = @group.people
                    .order(:name)
                    .offset(@page * page_size)
                    .limit(page_size)

    render Groups::PeopleTable.new(people: @people, exclude_group: @group, page: @page, pages: @pages)
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find(params[:id])
  end

  def set_page
    @page = (params[:page] || 0).to_i
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

  def page_size
    @page_size ||= Constants::VIEW_TABLE_LIST_LIMIT
  end
end
