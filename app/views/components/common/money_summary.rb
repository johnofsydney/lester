class Common::MoneySummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
	end

  def template
    if money_in.present? || money_out.present?
      hr
      h4 { 'Money Summary *' }
      h6 do
        plain '* transfers in and out'
        em { ' ...that we know about' }
      end
      if money_in.present?
        div(class: 'col') do
          h5 { 'Money In' }
          p { money_in }

          render Common::MoneyGraphs.new(entity:)
        end
      end
      if money_out.present?
        div(class: 'col') do
          h5 { 'Money Out' }
          p { money_out }

          render Common::MoneyGraphs.new(entity:, giver: true)
        end
      end
    end
  end

  def money_in
    amount = Transfer.where(taker_type: entity.class.name, taker_id: entity.id).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def money_out
    amount = Transfer.where(giver_type: entity.class.name, giver_id: entity.id).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end
end
