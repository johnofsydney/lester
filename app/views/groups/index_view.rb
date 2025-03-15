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
            a(href: "/groups/#{group.id}", data_turbo: "false") { group.display_name }
            if group.parent_groups.where(category: true).any?
              div do
                group.parent_groups.where(category: true).each do |parent_group|
                  parent_group_button(parent_group)
                end
              end
            end
          end
        end
      end

      render Common::PageNav.new(pages:, page:, klass: 'group')
    end
  end

  private

  attr_reader :groups, :page, :pages, :subheading

  def parent_group_button(parent_group)
    a(
      href: "/groups/#{parent_group.id}",
      class: 'btn btn-sm',
      style: "#{color_styles(parent_group)}; margin-left: 5px;",
      data_turbo: "false"
    ) { parent_group.name }
  end
end