class Groups::Heading < ApplicationView
  # include ActionView::Helpers::NumberHelper

  attr_reader :group #, :depth

	def initialize(group:)
		@group = group
    # @depth = depth
	end

	def template
    div(class: 'heading') do
      href = "https://www.google.com/search?q=#{group.name}"
      a(
        href:,
        class: 'btn w-100',
        style: button_styles(group),
        target: :_blank
      ) { group.name }
    end
  end
end