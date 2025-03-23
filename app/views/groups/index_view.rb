class Groups::IndexView < ApplicationView
  HIGHLIGHT_THRESHOLD = 3739

  def initialize(groups:, page:, pages:, subheading: nil)
    @groups = groups
    @page = page
    @pages = pages
    @subheading = subheading
  end

  def template
    div(class: 'mt-3 mb-3') do
      if subheading
        h4(class: 'font-italic') { subheading }
      else
        h2 { 'Groups' }
      end

      render Common::PageNav.new(pages:, page:, klass: 'group')

      div(class: 'list-group') do
        groups.each do |group|
          highlight = if Flipper.enabled?(:dev_highlighting)
            group.id > HIGHLIGHT_THRESHOLD ? 'highlight-row' : ''
          else
            ''
          end

          class_list = "list-group-item list-group-item-action flex-normal #{highlight}"
          div(class: class_list) do
            group_name_link(group)

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
      class: subheading.present? ? 'btn btn-sm desktop-only' : 'desktop-only',
      style: subheading.present? ? "#{color_styles(group)}; margin-left: 5px;" : '',
      link_text: group.name.truncate(100)
    )
    link_for(
      entity: group,
      class: subheading.present? ? 'btn btn-sm mobile-only' : 'mobile-only',
      style: subheading.present? ? "#{color_styles(group)}; margin-left: 5px;" : '',
      link_text: group.name.truncate(50)
    )
  end

  attr_reader :groups, :page, :pages, :subheading
end
