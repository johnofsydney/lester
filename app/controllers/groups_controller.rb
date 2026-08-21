class GroupsController < ApplicationController
  rate_limit to: Constants::CONTROLLER_RATE_LIMIT, within: 1.minute, with: -> { redirect_to search_path, alert: 'Too many requests, Please try in a minute...' } unless Rails.env.test? || Rails.env.development?

  include Constants

  before_action :set_group, only: %i[ show ]
  before_action :increment_views, only: %i[ show ]

  def index
    groups = Group.order(:name).page(params[:page])

    render Groups::IndexView.new(groups:)
  end

  def show
    if @group.nodes_count > Constants::TOO_MANY_CONNECTIONS_THRESHOLD
      render json: { message: 'too many nodes' }
      return
    end

    if @group.cache_fresh?
      render Groups::ShowView.new(group: @group)
    else
      Cache::BuildGroupCachedDataJob.perform_async(@group.id)
      render Common::PleaseRefreshLater.new(entity: @group)
    end
  end

  def reload
    @group = Group.find(params[:id])
    Cache::BuildGroupCachedDataJob.perform_async(@group.id)

    render Groups::ShowView.new(group: @group.reload)
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
    group = Group.find(params[:group_id])

    people = Kaminari.paginate_array(
      group.cached
           .direct_connections
           .filter { |c| c['klass'] == 'Person' }
           .sort_by { |c| c['name'] }
    ).page(params[:page])

    #  passing an array of hashes to the view
    render Groups::PeopleTable.new(people:, exclude_group: group)
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
    people_ids = group_params['people_ids'].compact_blank.map(&:to_i)

    people_ids.each do |id|
      person = Person.find(id)
      person.groups << group unless person.groups.include?(group)
    end

    group
  end

  def increment_views
    return if Current.user

    @group.increment!(:views)
  end
end
