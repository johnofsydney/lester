class HomeController < ApplicationController
  layout -> { ApplicationLayout }

  def index
    render Home::IndexView.new
  end
end
