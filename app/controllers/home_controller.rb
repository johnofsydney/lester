class HomeController < ApplicationController
  # layout -> { ApplicationLayout }

  def todo
    render Home::TodoView.new
  end

  def index
    render Home::IndexView.new
  end

  def post_to_socials
    message = Person.all.sample.tweet_body
    BlueskyService.skeet(message)

    render json: { message: message }, status: :ok
  end
end
