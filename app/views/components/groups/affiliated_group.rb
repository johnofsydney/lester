class Groups::AffiliatedGroup < ApplicationView
	def initialize(group:)
    @group = group
	end

  attr_reader :group

	def template
    header_style = element_styles(group)

    div(class: 'group card border-light mb-3', style: 'max-width: 18rem;') do
      link_for(
        entity: group,
        class: 'btn btn-sm btn-outline-primary',
        style: button_styles(group),
        link_text: group.name
      )
    end
  end
end