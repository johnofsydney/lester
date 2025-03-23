class Common::Heading < ApplicationView
  attr_reader :entity

	def initialize(entity:)
		@entity = entity
	end

	def template
    div(class:"text-center mb-4") do
      div(class: 'heading display-6 fw-bold shadow') do
        entity.is_category? ? button_without_link : button_with_link
      end

      a(href: network_graph_link, class:"btn btn-primary btn-lg shadow-sm") do
        strong { 'Explore the Network Graph' }
      end
      p(class: 'font-italic mt-1') { "...a visualisation of connections to #{entity.name}..." }
    end
  end

  def button_with_link
    href = "https://www.google.com/search?q=#{entity.name}"

    a(
      href:,
      class: 'btn w-100 btn-lg',
      style: "#{color_styles(entity)}; font-size: 1em;",
      target: :_blank
    ) { entity.name }
  end

  def button_without_link
    button(
      class: 'btn w-100 btn-lg',
      style: "#{color_styles(entity)}; font-size: 1em;",
      ) { entity.name }
  end

  def network_graph_link
    entity.is_a?(Group) ? "/groups/#{entity.id}/network_graph" : "/people/#{entity.id}/network_graph"
  end
end