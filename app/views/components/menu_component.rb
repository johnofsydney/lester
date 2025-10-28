class MenuComponent < ApplicationView
  def initialize(entity: nil, new: nil)
    @entity = entity
    if new
      @new_path = new[:path]
      @new_text = new[:text]
    end
  end

  attr_reader :entity, :new_path, :new_text

  def view_template

    nav(class: 'navbar navbar-expand-lg navbar-light bg-light') do
      div(class: 'container-fluid') do
        # Hero phrase or logo
        a(class: 'navbar-brand brand-text', href: '/') { title }

        # hamburger for mobile
        button(
          class: 'navbar-toggler',
          type: 'button',
          data: { bs_toggle: 'collapse', bs_target: '#navbarSupportedContent' },
          aria: { controls: 'navbarSupportedContent', expanded: 'false', label: 'Toggle navigation' }
          ) do
          span(class: 'navbar-toggler-icon')
        end

        # Collapsible menu
        div(class: 'collapse navbar-collapse justify-content-end', id: 'navbarSupportedContent') do
          menu_items
        end
      end
    end


  end
    def title
      case Current.host
      when /localhost/
        'Local...'
      when /staging/
        'Staging'
      when /hatchbox/
        'Hatchbox'
      else
        'Join The Dots...'
      end
    end

    def menu_items
      ul(class: 'navbar-nav') do
        li(class: 'nav-item') do
          a(class: 'nav-link', href: '/search/') { 'Search' }
        end
        li(class: 'nav-item') do
          a(class: 'nav-link', href: '/groups/') { 'Groups' }
        end
        li(class: 'nav-item') do
          a(class: 'nav-link', href: '/people/') { 'People' }
        end
        li(class: 'nav-item') do
          a(class: 'nav-link', href: '/transfers/') { 'Transfers' }
        end
        li(class: 'nav-item') do
          a(class: 'nav-link', href: '/home/index/') { 'About' }
        end
        if Current.user
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/admin/') { 'Admin' }
          end
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/admin/logout') { 'Logout' }
          end
        else
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/admin/login') { 'Login' }
          end
        end
      end
    end
end
