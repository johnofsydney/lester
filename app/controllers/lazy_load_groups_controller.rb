class LazyLoadGroupsController < ApplicationController
  def show
    # this is the controller action defined by lazy_load_group_path and called in the turbo frame
    @group = Group.find(params[:id])
  end
end
