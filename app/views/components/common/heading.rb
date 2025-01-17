class Common::Heading < ApplicationView
  attr_reader :entity

	def initialize(entity:)
		@entity = entity
	end

	def template
    div(class: 'heading') do
      entity.is_category? ? button_without_link : button_with_link
    end
  end

  def button_with_link
    href = "https://www.google.com/search?q=#{entity.name}"

    a(
      href:,
      class: 'btn w-100 btn-lg',
      style: "#{color_styles(entity)}; font-size: 1.5em;",
      target: :_blank
    ) { entity.name }
  end

  def button_without_link
    button(
      class: 'btn w-100',
      style: "#{color_styles(entity)}; font-size: 1.5em;",
      ) { entity.name }
  end
end