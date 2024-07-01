class LazyLoadGroupsController < ApplicationController
  def show
    @group = Group.find(params[:id])
  end
end
