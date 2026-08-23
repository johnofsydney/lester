class PeopleController < ApplicationController
  rate_limit to: Constants::CONTROLLER_RATE_LIMIT, within: 1.minute, with: -> { redirect_to search_path, alert: 'Too many requests, Please try in a minute...' } unless Rails.env.test? || Rails.env.development?

  include Constants

  before_action :set_person, only: %i[ show post_to_socials]
  before_action :increment_views, only: %i[ show ]

  def index
    people = Person.order(:name)
                   .includes([:groups])
                   .page(params[:page])

    render People::IndexView.new(people:)
  end

  def show
    if @person.cache_fresh?
      render People::ShowView.new(person: @person, groups: paginated_groups_for(@person))
    else
      Cache::BuildPersonCachedDataJob.perform_async(@person.id)
      render Common::PleaseRefreshLater.new(entity: @person)
    end
  end

  def reload
    @person = Person.find(params[:id])
    Cache::BuildPersonCachedDataJob.perform_async(@person.id)
    @person.reload

    render People::ShowView.new(person: @person, groups: paginated_groups_for(@person))
  end

  def post_to_socials
    message = @person.tweet_body
    BlueskyService.skeet(message)

    render json: { message: message }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_person
    @person = Person.find(params[:id])
  end

  # Only allow a list of trusted parameters through. Including nested params for memberships
  def person_params
    params.require(:person).permit(:name, memberships_attributes: [:id, :title, :start_date, :end_date, :_destroy])
  end

  def increment_views
    return if Current.user

    @person.increment!(:views)
  end

  def paginated_groups_for(person)
    Kaminari.paginate_array(person.cached.affiliated_groups).page(params[:groups_page])
  end
end