# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :host

  def local_host?
    host.match?(/localhost/)
  end
end