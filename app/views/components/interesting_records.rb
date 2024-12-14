class InterestingRecords < ApplicationView
  include ActionView::Helpers::NumberHelper

  def initialize(records: nil)
    @records = records
  end

  attr_reader :records

  def template
    list_group_options = "list-group mb-4"
    div(class: 'suggestions-container') do
      h3(class: 'text-secondary') { 'Suggestions' }
      div(class: 'row mt-4') do
        Group.major_political_categories.find_each do |group|
          div(class: 'col') do
            a(
              href: "/groups/#{group.id}",
              class: 'btn w-100',
              style: "#{color_styles(group)}; height: 100%",
              target: :_blank
            ) { group.name }
          end
        end
      end
      div(class: 'row mt-4') do
        div(class: 'col-md-4') do
          h6(class: 'column-heading text-primary mb-3') { 'Categories' }
          div(class: list_group_options) do
            Group.other_categories.find_each do |group|
              div(class: 'class: list-group-item list-group-item-action') do
                a(href: "/groups/#{group.id}") { group.name }
              end
            end
          end
        end
        div(class: 'col-md-4') do
          h6(class: 'column-heading text-primary mb-3') { 'People' }
          div(class: list_group_options) do

            @records.people.each do |record|
              div(class: 'class: list-group-item list-group-item-action') do
                a(href: "/people/#{record.id}") { record.name }
              end
            end
          end
        end
        div(class: 'col-md-4') do
          h6(class: 'column-heading text-primary mb-3') { 'Groups' }
          div(class: list_group_options) do
            @records.groups.each do |record|
              div(class: 'class: list-group-item list-group-item-action') do
                a(href: "/groups/#{record.id}") { text_for_group(record) }
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