class Groups::IndexView < ApplicationView
  def initialize(groups:, page:, pages:, subheading: nil)
    @groups = groups
    @page = page
    @pages = pages
    @subheading = subheading
  end

  def view_template
    div(class: 'mt-3 mb-3') do
      if subheading
        h4(class: 'font-italic') { subheading }
      else
        h2 { 'Groups' }
      end

      render Common::PageNav.new(pages:, page:, klass: 'group')

      div(class: 'list-group') do
        groups.each do |group|
          class_list = 'list-group-item list-group-item-action flex-normal'
          div(class: class_list) do
            group_name_link(group)

            # TODO: this is usning un-cached data - decide whether to keep it
            render Common::CollapsibleButtonCollection.new(
              collection: group.parent_groups.where(category: true),
              entity: group,
              render_inside: 'div'
            )
          end
        end
      end

      render Common::PageNav.new(pages:, page:, klass: 'group')
    end
  end

  private

  def group_name_link(group)
    link_for(
      entity: group,
      class: 'desktop-only',
      link_text: group.name.truncate(100)
    )
    link_for(
      entity: group,
      class: 'mobile-only',
      link_text: group.name.truncate(50)
    )
  end

  attr_reader :groups, :page, :pages, :subheading
end
