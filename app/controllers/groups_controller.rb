class GroupsController < ApplicationController
  rate_limit to: Constants::CONTROLLER_RATE_LIMIT, within: 1.minute, with: -> { redirect_to search_path, alert: 'Too many requests, Please try in a minute...' } # unless Rails.env.test? || Rails.env.development?

  include Constants

  before_action :set_group, only: %i[ show edit update destroy ]
  before_action :set_page, only: %i[ index ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  def index
    groups = Group.where.not(category: true).order(:name).limit(page_size).offset(paginate_offset).to_a
    pages = (Group.where.not(category: true).count.to_f / page_size).ceil

    render Groups::IndexView.new(groups:, page: @page, pages:)
  end

  def show
    if @group.cache_fresh?
      render Groups::ShowView.new(group: @group)
    else
      BuildGroupCachedDataJob.perform_async(@group.id)
      render Common::PleaseRefreshLater.new
    end
  end

  def reload
    @group = Group.find(params[:id])
    BuildGroupCachedDataJob.perform_async(@group.id)

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
    # This action used to have pagination. TODO: re-add pagination into the new format?
    group = Group.find(params[:group_id])
    page = params[:page].to_i
    pages = (group.people.count.to_f / page_size).ceil

    people = group.cached
                  .direct_connections
                  .filter { |c| c['klass'] == 'Person' }
                  .sort_by { |c| c['name'] }

    #  passing an array of hashes to the view
    render Groups::PeopleTable.new(people:, exclude_group: group, page:, pages:)
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

  def page_size
    return 250

    @page_size ||= Constants::PAGE_LIMIT
  end
end
