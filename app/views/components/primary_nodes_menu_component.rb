class PrimaryNodesMenuComponent < ApplicationView
	def initialize(entity:)
		@entity = entity
	end

  attr_reader :entity

	def template
    h2 { "The main nodes connected to #{entity.name}" }
    entity.nodes.each do |primary_node|
      div(class: 'list-group-item flex-normal') do
        div do
          a(href: "/#{class_of(primary_node)}/#{primary_node.id}", class: 'btn-primary btn', style: button_styles(primary_node)) { primary_node.name }
        end
        div do
          primary_node.nodes.each do |secondary_node|
            a(href: "/#{class_of(secondary_node)}/#{secondary_node.id}", class: 'btn-secondary btn btn-sml', style: button_styles(secondary_node) ) { secondary_node.name }
          end
        end
      end
    end
	end
end
