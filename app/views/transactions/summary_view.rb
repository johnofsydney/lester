class Transactions::SummaryView < ApplicationView
  include ActionView::Helpers::NumberHelper

	def initialize(summaries:)
		@summaries = summaries
	end

	def template
		h1 { 'transactions summary' }
	end
end