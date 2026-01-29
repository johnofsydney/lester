class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include Pagination
  include UrlBasedContent

  before_action :set_current_user

  private

  # def redirect_to_busy
  #   # render 'application/busy', status: :too_many_requests
  #   redirect_to root_url, alert: "Too many signups on domain!"
  # end

  def set_current_user
    Current.user = current_admin_user # Assuming current_user is provided by Devise or similar
  end
end
