class Components::Footer < ApplicationView
	# def initialize(transaction:)
	# 	@transaction = transaction
	# end

	def template
    # main menu
    a(href: '/groups/', class: 'btn btn-primary') { 'Groups' }
    a(href: '/transactions/', class: 'btn btn-primary') { 'Transactions' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
    a(href: '/imports/annual_donor/', class: 'btn btn-primary') { 'TEMP | IMPORT DONATIONS' }
	end
end