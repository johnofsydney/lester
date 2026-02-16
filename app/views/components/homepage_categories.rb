class HomepageCategories < ApplicationView
  include ActionView::Helpers::NumberHelper

  # Categories that we don't want to show on the homepage
  BLACKLISTED_CATEGORY_NAMES = ['Charities']

  def initialize(records: nil)
    @records = records
  end

  attr_reader :records

  def view_template
    div(class: 'suggestions-container mt-3 mb-3') do
      div(class: 'row g-3') do

        # Maybe temporary - but for now at least, omit charities from homepage categories
        display_categories = (Group.major_political_categories + Group.other_categories).reject { |group| BLACKLISTED_CATEGORY_NAMES.include?(group.name) }

        display_categories.each do |group|
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
