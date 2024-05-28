class Common::Heading < ApplicationView
  attr_reader :entity

	def initialize(entity:)
		@entity = entity
	end

	def template
    div(class: 'heading') do
      href = "https://www.google.com/search?q=#{entity.name}"
      a(
        href:,
        class: 'btn w-100',
        style: button_styles(entity),
        target: :_blank
      ) { entity.name }
    end
  end
end