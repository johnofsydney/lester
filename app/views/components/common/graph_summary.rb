class Common::GraphSummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
  end

  def template
    turbo_frame(id: 'money_summary') do
      if entity.cached.money_in.present? || entity.cached.money_out.present?
        div(class: 'margin-above ') do

          if entity.cached.money_in.present?
            div(class: 'col') do
              render Common::MoneyGraphs.new(entity:, giver: false)
            end
          end
          if entity.cached.money_out.present?
            div(class: 'col') do
              render Common::MoneyGraphs.new(entity:, giver: true)
            end
          end
        end

      end
    end
  end
end
