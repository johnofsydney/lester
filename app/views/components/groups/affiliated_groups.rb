class Groups::AffiliatedGroups < ApplicationView
  attr_reader :group, :affiliated_groups, :tags

  def initialize(group:, affiliated_groups:, tags:)
    @group = group
    @affiliated_groups = affiliated_groups
    @tags = tags
  end

  def view_template
    turbo_frame(id: 'affiliated_groups') do
      if tags.present?
        div(class: 'row mt-3 mb-3') do
          h4(class: 'font-italic') { 'Tags' }

          render Common::PageNav.new(
            collection: tags,
            path: "/groups/affiliated_groups/#{group.id}",
            param_name: 'tags_page',
            extra_params: { groups_page: affiliated_groups.current_page }
          )

          table(class: 'table table-striped responsive-table') do
            tr do
              th { 'Tags' }
              th { '(Last) Position' }
            end
            tags.each do |tag|
              render Common::TableRow.new(hentity: tag)
            end
          end
        end
      end

      if affiliated_groups.present?
        div(class: 'row mt-3 mb-3') do
          h4(class: 'font-italic') { 'Affiliated Groups' }

          render Common::PageNav.new(
            collection: affiliated_groups,
            path: "/groups/affiliated_groups/#{group.id}",
            param_name: 'groups_page',
            extra_params: { tags_page: tags.current_page }
          )

          table(class: 'table table-striped responsive-table') do
            tr do
              th { 'Group' }
              th { '(Last) Position' }
            end
            affiliated_groups.each do |affiliated_group|
              render Common::TableRow.new(hentity: affiliated_group)
            end
          end
        end
      end
    end
  end
end
