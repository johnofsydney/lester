class Common::MoneySummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  	def initialize(entity:)
		@entity = entity
	end

  def template
    if money_in.present? || money_out.present?
      hr
      div(class: 'row') do
        h2 { 'Money Summary' }
        div(class: 'col') do
          h3 { 'Money In' }
          p { money_in }

          # TODO: make this work for people as well
          if money_in.present? && entity.is_a?(Group)
            turbo_frame(id: 'money_in_charts', src: lazy_load_group_path, loading: :lazy) do
              p do
                p { 'Loading Chart...'}
                hr
              end
            end
          end
        end
        div(class: 'col') do
          h3 { 'Money Out' }
          p { money_out }

          # TODO: make this work for people as well
          if money_out.present? && entity.is_a?(Group)
            turbo_frame(id: 'money_out_charts', src: lazy_load_group_path, loading: :lazy) do
              p do
                p { 'Loading Chart...'}
                hr
              end
            end
          end
        end
      end
    end
  end

  def money_in
    amount = Transfer.where(taker: entity).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def money_out
    amount = Transfer.where(giver: entity).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end
end