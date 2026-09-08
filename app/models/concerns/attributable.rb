module Attributable
  extend ActiveSupport::Concern

  included do
    before_create :set_attributed_to
  end

  private

  def set_attributed_to
    self.attributed_to ||= Current.admin_user? ? Current.user.email : 'system'
  end
end
