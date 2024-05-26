class Groups::MoneySummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group #, :depth

  	def initialize(group:)
		@group = group
    # @depth = depth
	end

  def template
    if money_in.present? || money_out.present?
      hr
      div(class: 'row') do
        h2 { 'Money Summary' }
        div(class: 'col') do
          h3 { 'Money In' }
          p { money_in }
        end
        div(class: 'col') do
          h3 { 'Money Out' }
          p { money_out }
        end
      end
    end
  end

  def money_in
    amount = Transfer.where(taker: group).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def money_out
    amount = Transfer.where(giver: group).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end
end