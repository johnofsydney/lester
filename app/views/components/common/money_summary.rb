class Common::MoneySummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
  end

  def template
    turbo_frame(id: 'money_summary') do
      if money_in.present? || money_out.present?
        div(class: 'margin-above ') do

          # div(id: 'summary', class: 'graph rounded bg-light mt-3') do
          #   h4 do
          #     span {title}
          #     span { ' ' }
          #     span {
          #       a(href: "/about", class: 'gentle-link') { '...' }
          #     }
          #   end
          #   if money_in.present? && money_out.present?
          #     div(id: 'in-out-totals') do
          #       h6 { "To #{entity.name}: #{money_in}" } if money_in
          #       h6 { "From #{entity.name}: #{money_out}" } if money_out
          #     end
          #   end

          # end

          if money_in.present?
            div(class: 'col') do
              render Common::MoneyGraphs.new(entity:, giver: false)
            end
          end
          if money_out.present?
            div(class: 'col') do
              render Common::MoneyGraphs.new(entity:, giver: true)
            end
          end
        end

      end
    end
  end

  def title
    to_or_from = if money_in.present? && money_out.present?
                    'to & from'
                  elsif money_in.present?
                    'to'
                  elsif money_out.present?
                    'from'
                  end


    aggregate_suffix = if money_in.present? && money_out.present?
                         nil
                       elsif money_in.present?
                         ": #{money_in}"
                       elsif money_out.present?
                         ": #{money_out}"
                       end

    if entity.is_category?
      "Aggregate Transfers #{to_or_from} member groups and people of category: #{entity.name.upcase}"
    else
      "Transfers #{to_or_from} #{entity.name.upcase}#{aggregate_suffix}"
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
