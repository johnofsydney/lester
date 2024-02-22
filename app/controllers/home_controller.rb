class HomeController < ApplicationController
  layout -> { ApplicationLayout }

  def todo
    render Home::TodoView.new
  end

  def index
    render Home::IndexView.new
  end
end
