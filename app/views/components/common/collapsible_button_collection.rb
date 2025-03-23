class Common::CollapsibleButtonCollection < ApplicationView
  attr_reader :entity, :groups, :render_inside

	def initialize(entity:, groups:, render_inside:)
		@entity = entity
    @groups = groups
    @render_inside = render_inside
	end

	def template
    render_inside_td if render_inside == 'td'
    render_inside_div if render_inside == 'div'

  rescue => e
    p "*********************"
    puts e.message
    puts e.backtrace
    p "*********************"
  end

  def render_inside_td
    td(class: 'mobile-display-none', style: 'text-align: right;') do

      div do
        if groups.count < 8
          several_buttons
        else
          single_button
        end
      end
    end

    td(class: 'desktop-display-none', style: 'text-align: right;') do

      single_button
    end
  end

  def render_inside_div
    div(class: 'mobile-display-none', style: 'text-align: right;') do

      if groups.count < 8
        several_buttons
      else
        single_button
      end
    end
    div(class: 'desktop-display-none', style: 'text-align: right;') do

      single_button
    end
  end

  def several_buttons
    groups.each do |group|
      link_for(
        entity: group,
        class: 'btn btn-sm btn-collection',
        style: "#{color_styles(group)}; margin-left: 5px;",
        link_text: group.name
      )
    end
  end

  def single_button
    link_for(
      entity: entity,
      class: 'btn btn-sm',
      style: "#{color_styles(entity)}; margin-left: 5px;",
      link_text: "#{groups.count} other #{'Group'.pluralize(groups.count)}"
    )
  end
end
