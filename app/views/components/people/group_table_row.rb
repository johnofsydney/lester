class People::GroupTableRow < ApplicationView
  def initialize(group:, exclude_person: nil)
    @group = group
    @exclude_person = exclude_person
    @membership = Membership.find_by(group: group, member: exclude_person)
  end

  attr_reader :group, :exclude_person, :membership

  def template
    tr do
      td do
        a(href: "/groups/#{group.id}") { group.name }
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
        collection: group.people - [exclude_person],
        entity: group,
        render_inside: 'td',
        contains_only: 'people'
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
      result += " (#{position.formatted_start_date} - #{position.formatted_end_date})"
    elsif position.start_date.present?
      result += " (since #{position.formatted_start_date})"
    elsif position.end_date.present?
      result += " (until #{position.formatted_end_date})"
    end

    result
  end
end
