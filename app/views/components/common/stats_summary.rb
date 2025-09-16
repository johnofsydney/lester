class Common::StatsSummary < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :entity

  def initialize(entity:)
		@entity = entity
  end

  def template
    comment { 'Stats Section' }
    div(class: 'row text-center mb-4') do
      money_box

      people_box unless entity.is_a?(Person)

      group_box
    end
  end

  def column_class
    entity.is_a?(Group) ? 'col-md-4' : 'col-md-6'
  end

  def groups_count
    entity.cached.direct_connections.count {|c| c['klass'] == 'Group' }
  end

  def people_count
    entity.cached.direct_connections.count {|c| c['klass'] == 'Person' }
  end

  def money_box
    div(class: column_class) do
      div(class: 'p-3 bg-light rounded shadow-sm equal-height border') do
        if entity.cached.money_in.present? || entity.cached.money_out.present?
          div(class: 'vertical-centre-value') do
            table_style = (entity.cached.money_in.present? && entity.cached.money_out.present?) ? 'margin-bottom: 1rem;' : 'margin-bottom: 0;'
            table(class: 'table table-sm  no-border-table', style: table_style) do
              tbody do
                tr do
                  td(class: 'h5 fw-bold mb-0') { entity.cached.money_in }
                  td { 'in' }
                end if entity.cached.money_in.present?
                tr do
                  td(class: 'h5 fw-bold mb-0') { entity.cached.money_out }
                  td { 'out' }
                end if entity.cached.money_out.present?
              end
            end
          end
        end
        p(class: 'text-muted small bottom-text') { 'Transfers' }
      end
    end
  end

  def people_box
    div(class: column_class) do
      div(class: 'p-3 bg-light rounded shadow-sm equal-height border') do
        div(class: 'vertical-centre-value') do
          p(class: 'h5 fw-bold mb-0') { people_count }
        end
        p(class: 'text-muted small bottom-text') { 'People in Group' }
      end
    end
  end

  def group_box
    div(class: column_class) do
      div(class: 'p-3 bg-light rounded shadow-sm equal-height border') do
        div(class: 'vertical-centre-value') do
          p(class: 'h5 fw-bold mb-0') { groups_count }
        end
          p(class: 'text-muted small bottom-text') { "Connected #{'Group'.pluralize(groups_count)}" }
      end
    end
  end
end