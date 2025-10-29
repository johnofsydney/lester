class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include Pagination
  include UrlBasedContent

  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_admin_user # Assuming current_user is provided by Devise or similar
  end
end
