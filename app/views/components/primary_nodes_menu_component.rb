class PrimaryNodesMenuComponent < ApplicationView
	def initialize(entity:, entities_to_exclude: [])
		@entity = entity
    @nodes = entity.nodes - entities_to_exclude
	end

  attr_reader :entity

	def template
    div(class: 'flex-normal') do
      @nodes.each do |primary_node|
        div do
          link_for(
            entity: primary_node,
            class: 'btn-primary btn',
            style: button_styles(primary_node)
          )
        end
      end
    end
	end

  def link_for(entity:, class: '', style: '')
    a(href: "/#{class_of(entity)}/#{entity.id}", class:, style:) { entity.name }
  end
end
