class Common::StatsSummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
  end

  def template
    comment { "Stats Section" }
    div(class: "row text-center mb-4") do
      div(class: column_class) do
        div(class: "p-3 bg-light rounded shadow-sm equal-height") do
          div(class: 'vertical-centre-value') do
            table_style = (entity.money_in.present? && entity.money_out.present?) ? "margin-bottom: 1rem;" : "margin-bottom: 0;"
            table(class: "table table-sm  no-border-table", style: table_style) do
              tbody do
                tr do
                  td { "in" }
                  td(class: "h5 fw-bold mb-0") { entity.money_in }
                end if entity.money_in.present?
                tr do

                  td(class: "h5 fw-bold mb-0") { entity.money_out }
                  td { "out" }
                end if entity.money_out.present?
              end
            end
          end if entity.money_in.present? || entity.money_out.present?
          p(class: "text-muted small bottom-text") { "Transfers" }
        end
      end
      div(class: column_class) do
        div(class: "p-3 bg-light rounded shadow-sm equal-height") do
          div(class: 'vertical-centre-value') do
            p(class: "h5 fw-bold mb-0") { entity.people.count }
          end
          p(class: "text-muted small bottom-text") { "People in Group" }
        end
      end unless entity.is_a?(Person)
      div(class: column_class) do
        div(class: "p-3 bg-light rounded shadow-sm equal-height") do
          div(class: 'vertical-centre-value') do
            p(class: "h5 fw-bold mb-0") do
              entity.is_a?(Group) ? entity.affiliated_groups.count : entity.groups.count
            end
          end
          p(class: "text-muted small bottom-text") { "Connected Groups" }
        end
      end
    end
  end

  def column_class
    "col-md-4"
  end
end