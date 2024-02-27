class MenuComponent < ApplicationView
  def initialize(entity: nil, new: nil)
    @entity = entity
    if new
      @new_path = new[:path]
      @new_text = new[:text]
    end
  end

  attr_reader :entity, :new_path, :new_text

  def template
    nav(class: 'navbar navbar-expand-lg navbar-light bg-light') do
      a(class: 'navbar-brand', href: '/') { 'LESTER' }
      button(class: 'navbar-toggler', type: 'button', data: { toggle: 'collapse', target: '#navbarNav', aria: { controls: 'navbarNav', expanded: 'false', label: 'Toggle navigation' } }) do
        span(class: 'navbar-toggler-icon')
      end
      div(class: 'collapse navbar-collapse justify-content-end', id: 'navbarNav') do
        ul(class: 'navbar-nav') do
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/groups/') { 'Groups' }
          end
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/transfers/') { 'Transfers' }
          end
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/people/') { 'People' }
          end
          li(class: 'nav-item') do
            a(class: 'nav-link', href: '/imports/') { 'IMPORT DONATIONS' }
          end
          li(class: 'nav-item') do
            link_for(entity: entity, class: 'nav-link', link_text: 'Edit', action: 'edit') if entity
            a(class: 'nav-link', href: new_path) { new_text } if new_path
          end
          # unless current_user
            li(class: 'nav-item') do
              a(class: 'nav-link', href: '/users/sign_in') { 'Login' }
            end
          # else
            li(class: 'nav-item') do
              a(class: 'nav-link', href: '/users/sign_out', data: { turbo_method: :delete }) { 'Logout' }
            end
          # end

        end
      end
    end
  end
end
