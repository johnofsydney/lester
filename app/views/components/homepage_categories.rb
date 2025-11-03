class HomepageCategories < ApplicationView
  include ActionView::Helpers::NumberHelper

  def initialize(records: nil)
    @records = records
  end

  attr_reader :records

  def view_template
    style = Current.local_host? ? 'background-color: #555555' : 'background-color: #333333; padding: 20px; border-radius: 8px;'

    div(class: 'suggestions-container mt-3 mb-3') do
      div(class: 'row g-3') do

        (Group.major_political_categories + Group.other_categories).each do |group|
          div(class: 'col-md-4') do
            div(class: 'card shadow-sm', style: "#{color_styles(group)}; height: 100%") do
              div(class: 'card-body text-center') do
                a(
                  href: "/groups/#{group.id}",
                  class: 'btn w-100',
                  style: "#{color_styles(group)}; height: 100%"
                ) { group.name }
              end
            end
          end
        end
      end
    end
  end
end
