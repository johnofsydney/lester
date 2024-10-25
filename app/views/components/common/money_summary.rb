class Common::MoneySummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
  end

  def template
    if money_in.present? || money_out.present?
      div(class: 'margin-above ') do

        div(id: 'summary', class: 'graph rounded bg-light mt-3') do
          h4 do
            span {title}
            span { ' ' }
            span {
              a(href: "/about", class: 'gentle-link') { '...' }
            }
          end
          if money_in.present? && money_out.present?
            div(id: 'in-out-totals') do
              h6 { "To #{entity.name}: #{money_in}" } if money_in
              h6 { "From #{entity.name}: #{money_out}" } if money_out
            end
          end

        end

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

  def title
    to_or_from = if money_in.present? && money_out.present?
                    'To & From'
                  elsif money_in.present?
                    'To'
                  elsif money_out.present?
                    'From'
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

  def category_title
    "Aggregate Transfers to / from to member groups and people of category: #{entity.name.upcase}"
  end

  def money_in
    if is_category?
      to_groups = Transfer.where(taker_type: 'Group', taker_id: [entity.groups.pluck(:id)]).sum(:amount)
      to_people = Transfer.where(taker_type: 'Person', taker_id: [entity.people.pluck(:id)]).sum(:amount)

      amount = to_groups + to_people
    else
      amount = Transfer.where(taker_type: entity.class.name, taker_id: entity.id).sum(:amount)
    end

    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def money_out
    if is_category?
      from_groups = Transfer.where(giver_type: 'Group', giver_id: [entity.groups.pluck(:id)])
                            .where.not(taker_id: [entity.groups.pluck(:id)])
                            .sum(:amount)
      from_people = Transfer.where(giver_type: 'Person', giver_id: [entity.people.pluck(:id)]).sum(:amount)

      amount = from_groups + from_people
    else
      amount = Transfer.where(giver_type: entity.class.name, giver_id: entity.id).sum(:amount)
    end
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def is_category?
    entity.is_category?
  end
end
