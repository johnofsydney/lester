class Groups::PersonTableRow < ApplicationView
	def initialize(person:, exclude_group: nil)
		@person = person
    @exclude_group = exclude_group
    @membership = Membership.find_by(group: exclude_group, member: person)
	end

  attr_reader :person, :exclude_group, :membership

  def template
    tr do
      td do
        span { link_for(entity: person) }
        if membership.evidence.present?
          span { '   ' }
          span { a(href: membership.evidence, class: 'gentle-link', target: '_blank') { '...' } }
        end
      end
      td do
        span {last_position_and_title}
        if last_position&.evidence.present?
          span { '   ' }
          span { a(href: last_position.evidence, class: 'gentle-link', target: '_blank') { '...' } }
        end
      end

      render Common::CollapsibleButtonCollection.new(
        entity: person,
        groups: person.groups.where.not(id: exclude_group.id),
        render_inside: 'td'
      )
    end
  end

  private

  def last_position
    membership&.last_position
  end

  def last_position_and_title
    position = membership&.last_position

    return '' unless position

    result = position.title
    return '' unless result

    if position.end_date.present? && position.start_date.present?
      if position.end_date == position.start_date
        result += " | (#{position.formatted_start_date})"
      else
        result += " | (#{position.formatted_start_date} - #{position.formatted_end_date})"
      end
    elsif position.start_date.present?
      result += " | (since #{position.formatted_start_date})"
    elsif position.end_date.present?
      result += " | (until #{position.formatted_end_date})"
    end

    result
  end
end
