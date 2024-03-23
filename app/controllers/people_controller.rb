class PeopleController < ApplicationController
  before_action :set_person, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: %i[ new edit update destroy ]

  layout -> { ApplicationLayout }

  # GET /people or /people.json
  def index
    @people = Person.all
    render People::IndexView.new(people: @people)
  end

  # GET /people/1 or /people/1.json
  def show
    render People::ShowView.new(person: @person)

  end

  # GET /people/new
  def new
    return unless current_user
    @person = Person.new
  end

  # GET /people/1/edit
  def edit
    return unless current_user
    # phlex not working yet. form is hard. has nesting
    # render People::EditView.new(person: @person)
  end

  # POST /people or /people.json
  def create
    return unless current_user

    @person = Person.new(person_params)

    respond_to do |format|
      if @person.save
        new_membership_params = params[:person][:memberships_attributes][:NEW_RECORD]
        if new_membership_params
          @person.memberships.create(new_membership_params.permit(:group_id, :title, :start_date, :end_date))
        end
        format.html { redirect_to person_url(@person), notice: "Person was successfully created." }
        format.json { render :show, status: :created, location: @person }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /people/1 or /people/1.json
  def update
    return unless current_user

    respond_to do |format|
      if @person.update(person_params)
        new_membership_params = params[:person][:memberships_attributes][:NEW_RECORD]
        if new_membership_params
          @person.memberships.create(new_membership_params.permit(:group_id, :title, :start_date, :end_date))
        end
        format.html { redirect_to person_url(@person), notice: "Person was successfully updated." }
        format.json { render :show, status: :ok, location: @person }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1 or /people/1.json
  def destroy
    return unless current_user

    @person.destroy

    respond_to do |format|
      format.html { redirect_to people_url, notice: "Person was successfully destroyed." }
      format.json { head :no_content }
    end
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