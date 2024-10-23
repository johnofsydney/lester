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
      if is_category?
        p { "Figures below are aggregates of the payments to member groups and people of #{entity.name}" }
      else
        p { "Payments directly to & from #{entity.name}" }
      end
      if money_in.present?
        div(class: 'col') do
          h5 { 'Money In' }
          p { money_in }

          render Common::MoneyGraphs.new(entity:, giver: false)
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
