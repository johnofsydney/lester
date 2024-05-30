class PeopleTransfersController < ApplicationController
  def show
    @person = Person.find(params[:id])
  end
end