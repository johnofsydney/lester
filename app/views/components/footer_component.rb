class FooterComponent < ApplicationView
	def initialize(entity:)
		@entity = entity
	end

  attr_reader :entity

	def template
    # main menu
    a(href: '/groups/', class: 'btn btn-primary') { 'Groups' }
    # a(href: '/transactions/', class: 'btn btn-primary') { 'Transactions' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
    a(href: '/imports/annual_donor/', class: 'btn btn-primary') { 'TEMP | IMPORT DONATIONS' }
    a(href: "/#{class_of(entity)}/#{entity.id}/edit", class: 'btn btn-primary') { "Edit #{entity.name}" }
	end
end
