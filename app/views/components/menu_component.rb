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
    case Current.host
    when /localhost|michaelwest/
      render partial('shared/mwm_header_file')
    when /staging/
      render partial('shared/mwm_header_file')
    else
      standard_header
    end
  end

  def standard_header
    nav(class: "navbar navbar-expand-lg navbar-light #{background_color}") do
      div(class: 'container-fluid') do
        # Hero phrase or logo
        a(class: "navbar-brand brand-text #{text_color}", href: '/') { title }

        # hamburger for mobile
        button(
          class: 'navbar-toggler',
          type: 'button',
          data: { bs_toggle: 'collapse', bs_target: '#navbarSupportedContent' },
          aria: { controls: 'navbarSupportedContent', expanded: 'false', label: 'Toggle navigation' }
          ) do
          span(class: 'navbar-toggler-icon')
        end

        # collapsible menu
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

  def background_color
    if Current.local_host?
      'bg-dark'
    else
      'bg-light'
    end
  end

  def text_color
    if Current.local_host?
      'text-light'
    else
      'text-dark'
    end
  end

  def menu_items
    ul(class: 'navbar-nav') do
      li(class: 'nav-item') do
        a(class: "nav-link #{text_color}", href: '/search/') { 'Search' }
      end
      li(class: 'nav-item') do
        a(class: "nav-link #{text_color}", href: '/groups/') { 'Groups' }
      end
      li(class: 'nav-item') do
        a(class: "nav-link #{text_color}", href: '/people/') { 'People' }
      end
      li(class: 'nav-item') do
        a(class: "nav-link #{text_color}", href: '/transfers/') { 'Transfers' }
      end
      li(class: 'nav-item') do
        a(class: "nav-link #{text_color}", href: '/home/index/') { 'About' }
      end
      if Current.user
        li(class: 'nav-item') do
          a(class: "nav-link #{text_color}", href: '/admin/') { 'Admin' }
        end
        li(class: 'nav-item') do
          a(class: "nav-link #{text_color}", href: '/admin/logout') { 'Logout' }
        end
      else
        li(class: 'nav-item') do
          a(class: "nav-link #{text_color}", href: '/admin/login') { 'Login' }
        end
      end
    end
  end
end
