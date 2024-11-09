class PeopleController < ApplicationController
  before_action :set_person, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  layout -> { ApplicationLayout }

  def index
    people = Person.order(:name)
    render People::IndexView.new(people:)
  end
``
  def show
    render People::ShowView.new(person: @person)
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
end