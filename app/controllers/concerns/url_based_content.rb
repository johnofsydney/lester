module UrlBasedContent
  extend ActiveSupport::Concern

  included do
    before_action :set_url_based_content
  end

  private

  def set_url_based_content
    Current.host = request.url
  end
end