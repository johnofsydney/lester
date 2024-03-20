class Home::IndexView < ApplicationView
  def initialize
  end

  def template
    div(class: 'container') do
      div(class: 'jumbotron', style: 'background-color: #243447; color: white;') do
        h1(class: 'display-4') { 'follow the money' }
      end

      div(class: 'row') do

        a(href: '/home/todo') { 'TODO' }
      end

      footer(class: 'footer mt-auto py-3 bg-light') do
        div(class: 'container') do
          span(class: 'text-muted') { 'Place sticky footer content here.' }
        end
      end
    end
  end
end