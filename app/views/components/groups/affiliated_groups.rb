class Groups::AffiliatedGroups < ApplicationView

  attr_reader :group

  def initialize(group:)
    @group = group.cached
  end

  def view_template
    turbo_frame(id: 'affiliated_groups') do

      affiliated_groups = group.direct_connections.filter{ |c| (c['klass'] == 'Group') && !c['is_tag'] }
      parent_tags = group.direct_connections.filter{ |c| c['klass'] == 'Tag' }

      if parent_tags.present?
        h4(class: 'font-italic mt-3') { 'Tags' }

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Tags' }
            th { '(Last) Position' } if parent_tags.any? { |g| g['last_position'].present? }
          end
          parent_tags.sort_by { |group| group['name'] }.each do |tag|
            render Common::TableRow.new(hentity: tag)
          end
        end
      end

      if affiliated_groups.present?

        h4(class: 'font-italic mt-3') { 'Affiliated Groups' }

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Group' }
            th { '(Last) Position' } if affiliated_groups.any? { |g| g['last_position'].present? }
          end
          affiliated_groups.sort_by {|group| group['name'] }.each do |group|
            render Common::TableRow.new(hentity: group)
          end
        end
      end
    end
  end
end
