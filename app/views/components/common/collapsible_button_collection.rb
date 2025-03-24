class Common::CollapsibleButtonCollection < ApplicationView
  attr_reader :entity, :collection, :render_inside, :contains_only

	def initialize(entity:, collection:, render_inside:, contains_only: nil)
		@entity = entity
    @collection = collection
    @render_inside = render_inside
    @contains_only = contains_only
	end

	def template
    render_inside_td if render_inside == 'td'
    render_inside_div if render_inside == 'div'
  end

  def render_inside_td
    return td { ' ' } if collection.count < 1

    td(class: 'desktop-only', style: 'text-align: right;') do

      div do
        if collection.count < 8
          several_buttons
        else
          single_button
        end
      end
    end

    td(class: 'mobile-only', style: 'text-align: right;') do

      single_button
    end
  end

  def render_inside_div
    return div { ' ' } if collection.count < 1

    div(class: 'desktop-only', style: 'text-align: right;') do

      if collection.count < 8
        several_buttons
      else
        single_button
      end
    end
    div(class: 'mobile-only', style: 'text-align: right;') do

      single_button
    end
  end

  def several_buttons
    collection.each do |group_or_person|
      link_for(
        entity: group_or_person,
        class: 'btn btn-sm btn-collection',
        style: "#{color_styles(group_or_person)}; margin-left: 5px;",
        link_text: group_or_person.name
      )
    end
  end

  def single_button
    link_for(
      entity: entity,
      class: 'btn btn-sm btn-single',
      style: "#{color_styles(entity)}; margin-left: 5px;",
      link_text: link_text
    )
  end

  def link_text
    return "#{collection.count} members" if contains_only == 'people'

    "Member of #{collection.count} other #{'Group'.pluralize(collection.count)}"
  end
end
