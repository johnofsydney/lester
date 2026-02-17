class Groups::AffiliatedGroups < ApplicationView

  attr_reader :group
  def initialize(group:)
    @group = group.cached
  end

  def view_template
    turbo_frame(id: 'affiliated_groups') do

      affiliated_groups = group.direct_connections.filter{ |c| (c['klass'] == 'Group') && !c['is_category'] }
      parent_categories = group.direct_connections.filter{ |c| (c['klass'] == 'Group') && c['is_category'] }

      if parent_categories.present?
        h4(class: 'font-italic mt-3') { 'Categories' }

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Category' }
            th { '(Last) Position' } if parent_categories.any? { |g| g['last_position'].present? }
          end
          parent_categories.sort_by { |group| group['name'] }.each do |category|
            render Common::TableRow.new(hentity: category)
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
