class InterestingRecords < ApplicationView
  include ActionView::Helpers::NumberHelper

  def initialize(records: nil)
    @records = records
  end

  attr_reader :records

  def template
    list_group_options = "list-group mb-4"
    div(class: 'suggestions-container mt-3 mb-3') do
      # h3(class: 'text-secondary') { 'Suggestions' }
      div(class: "row g-3") do

        (Group.major_political_categories + Group.other_categories).shuffle.each do |group|
          div(class: "col-md-4") do
            div(class: "card shadow-sm", style: "#{color_styles(group)}; height: 100%") do
              div(class: "card-body text-center") do
                a(
                  href: "/groups/#{group.id}",
                  class: 'btn w-100',
                  style: "#{color_styles(group)}; height: 100%",
                ) { group.name }
              end
            end
          end
        end

      end


    end
  end

  def text(record)
    return text_for_transfer(record) if record.is_a?(Transfer)
    return text_for_group(record) if record.is_a?(Group)
    return text_for_person(record) if record.is_a?(Person)
  end

  def text_for_transfer(record)
    "#{number_to_currency(record.amount, precision: 0)} \nFrom: #{record.giver.name} \nTo: #{record.taker.name} \nYear: #{record.financial_year}"
  end

def text_for_group(record)
  name = record.name
  truncated_name = name.length > 40 ? "#{name[0, 20]}..." : name
  truncated_name
end

  def text_for_person(record)
    "#{record.name}"
  end
end