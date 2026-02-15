class Common::Heading < ApplicationView
  attr_reader :entity

  def initialize(entity:)
    @entity = entity
  end

  def view_template
    div(class:'text-center mb-4') do

      if entity.is_category?
        div(class: 'heading display-6 fw-bold shadow') do
          button_without_link
        end
        p do
          unless entity.id == Group.government_department_category.id
            plain 'This page shows all groups tagged with '
            strong { entity.name }
            plain '. The values in the graphs and tables relate to the '
            strong { 'groups' }
            plain ', which may be associated with other tags as well.'
          end
        end
      else
        div(class: 'heading display-6 fw-bold shadow') do
          button_with_link
        end

        a(href: network_graph_link, class:'btn btn-primary btn-lg shadow-sm') do
          strong { 'Explore the Network Graph' }
        end
        p(class: 'font-italic mt-1') { "...a visualisation of connections to #{entity.name}..." }
      end

      p { business_number_and_trading_names } if entity.business_number.present? || entity.trading_names.any?
    end
  end

  def button_with_link
    href = "https://www.google.com/search?q=#{entity.name}"

    a(
      href:,
      class: 'btn w-100 btn-lg',
      style: "#{color_styles(entity)}; font-size: 1em;",
      target: :_blank
    ) { entity.name }
  end

  def button_without_link
    button(
      class: 'btn w-100 btn-lg',
      style: "#{color_styles(entity)}; font-size: 1em;"
    ) { entity.name }
  end

  def network_graph_link
    entity.is_group? ? "/groups/#{entity.id}/network_graph" : "/people/#{entity.id}/network_graph"
  end

  def business_number_and_trading_names
    parts = []
    parts << a(href: "https://abr.business.gov.au/ABN/View?abn=#{entity.business_number}", target: :_blank) { "ABN: #{entity.business_number}" } if entity.business_number.present?
    parts << plain(" Also known as: #{entity.trading_names.map(&:name).join(', ')}") if entity.trading_names.any?

    parts.join(' | ')
  end
end
