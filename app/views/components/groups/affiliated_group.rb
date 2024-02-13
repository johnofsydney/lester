class Groups::AffiliatedGroup < ApplicationView
	def initialize(group:)
    @group = group
	end

  attr_reader :group

	def template
    header_style = element_styles(group)

    div(class: 'group card border-primary mb-3', style: 'max-width: 18rem;') do
      link_for(
        entity: group,
        class: 'btn btn-sm btn-outline-primary',
        style: button_styles(group),
        link_text: group.name
      )
      div(class: 'card-body text-primary') do

      end
    end
  end
end