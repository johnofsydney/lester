class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group, :depth

	def initialize(group:, depth:)
		@group = group
    @depth = depth
	end

	def template
    # all moved to the erb show page (for now?)
  end
end