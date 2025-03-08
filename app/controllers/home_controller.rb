class HomeController < ApplicationController
  layout -> { ApplicationLayout }

  def todo
    render Home::TodoView.new
  end

  def index
    render Home::IndexView.new
  end

  def suggestions
    render Home::MakeSuggestionView.new
  end

  def suggestion_received
    render Home::SuggestionReceivedView.new
  end

  def post_suggestions
    suggestion = Suggestion.new(suggestion_params)
    suggestion.status = 'new'
    suggestion.save
    redirect_to '/home/suggestion_received'
  end

  def suggestion_params
    @suggestion_params ||= params.permit(:headline, :description, :evidence, :suggested_by)
  end

  def post_to_socials
    message = Person.all.shuffle.last.summary
    BlueskyService.skeet(message)

    render json: { message: message }, status: :ok
  end
end
