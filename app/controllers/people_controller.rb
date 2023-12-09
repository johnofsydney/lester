class PeopleController < ApplicationController
  before_action :set_person, only: %i[ show edit update destroy ]
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
    @person = Person.new
    render People::EditView.new(person: @person)
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
    render People::EditView.new(person: @person)
  end

  # POST /people or /people.json
  def create
    @person = Person.new(person_params)

    respond_to do |format|
      if update_person(@person)
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
    respond_to do |format|
      if update_person(@person)
      # if @person.update(person_params)
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

    # Only allow a list of trusted parameters through.
    def person_params
      params.require(:person).permit!
      # params.require(:person).permit(:name, :group_ids)
    end

    def update_person(person)

      group_ids = person_params['group_ids'].select(&:present?).map(&:to_i)

      group_ids.each do |id|
        group = Group.find(id)
        person.groups << group unless person.groups.include?(group)
      end

      person.save
    end
end