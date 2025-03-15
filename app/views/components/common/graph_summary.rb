class Common::GraphSummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
  end

  def template
    turbo_frame(id: 'money_summary') do
      if entity.money_in.present? || entity.money_out.present?
        div(class: 'margin-above ') do

          if entity.money_in.present?
            div(class: 'col') do
              render Common::MoneyGraphs.new(entity:, giver: false)
            end
          end
          if entity.money_out.present?
            div(class: 'col') do
              render Common::MoneyGraphs.new(entity:, giver: true)
            end
          end
        end

      end
    end
  end

  def money_in
    # if is_category?
    #   amount = entity.category_incoming_transfers.sum(:amount)
    # else
    #   amount = entity.incoming_transfers.sum(:amount)
    # end

    # return unless amount.positive?

    # number_to_currency amount, precision: 0
    entity.money_in
  end

  def money_out
    # if is_category?
    #   amount = entity.category_outgoing_transfers.sum(:amount)
    # else
    #   amount = entity.outgoing_transfers.sum(:amount)
    # end
    # return unless amount.positive?

    # number_to_currency amount, precision: 0
    entity.money_out
  end

  def is_category?
    entity.is_category?
  end
end
