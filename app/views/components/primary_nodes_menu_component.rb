class PrimaryNodesMenuComponent < ApplicationView
	def initialize(entity:, entities_to_exclude: [])
		@entity = entity
    @nodes = entity.nodes - entities_to_exclude
	end

  attr_reader :entity

	def template
    div(class: 'flex-normal') do
      @nodes.each do |primary_node|

        if use_member_title?(entity, primary_node)
          membership = Membership.find_by(person: entity, group: primary_node) || Membership.find_by(person: primary_node, group: entity)
          return false unless membership
          if membership.start_date && membership.end_date
            period = "#{membership.start_date.year} - #{membership.end_date.year}"
          else
            ''
          end

          link_text = "#{primary_node.name} (#{membership.title}, #{period})"
        end

        div do
          link_for(
            entity: primary_node,
            class: 'btn-primary btn',
            style: button_styles(primary_node),
            link_text: link_text || primary_node.name
          )
        end
      end
    end
	end

  def use_member_title?(entity, primary_node)
    entity.is_a?(Person) && primary_node.is_a?(Group) || entity.is_a?(Group) && primary_node.is_a?(Person)
  end
end
