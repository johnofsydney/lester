class PeopleController < ApplicationController
  before_action :set_person, only: %i[ show edit update destroy post_to_socials]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]
  before_action :set_page, only: %i[ index ]

  layout -> { ApplicationLayout }

  def index
    people = Person.order(:name)
                   .limit(page_size)
                   .offset(paginate_offset)
                   .includes([:groups])
                   .to_a

    pages = (Person.count.to_f / page_size).ceil

    render People::IndexView.new(people:, page: @page, pages:)
  end

  def show
    if @person.cache_fresh?
      render People::ShowView.new(person: @person)
    else
      BuildPersonCachedDataJob.perform_async(@person.id)
      render plain: Constants::PLEASE_REFRESH_MESSAGE, status: 200
    end
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

  def page_size
    return 250

    @page_size ||= Constants::PAGE_LIMIT
  end

  def set_page
    @page = (params[:page] || 0).to_i
  end
end