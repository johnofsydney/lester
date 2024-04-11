class InterestingRecords < ApplicationView
  include ActionView::Helpers::NumberHelper

  def initialize(records: nil)
    @records = records
  end

  attr_reader :records

  def template
    div(class: 'margin-above') do
      h2 { 'Interesting and / or New Records' }
      div(class: 'row') do
        div(class: 'col') do
          ul do
            @records.transfers.each do |record|
              li do
                a(href: "/transfers/#{record.id}") { text(record) }
              end
            end
          end
        end
      end
      div(class: 'row') do

        div(class: 'col') do
          ul do
            @records.groups.each do |record|
              li do
                a(href: "/groups/#{record.id}") { text(record) }
              end
            end
          end
        end

        div(class: 'col') do
          ul do
            @records.people.each do |record|
              li do
                a(href: "/people/#{record.id}") { text(record) }
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
    "Transfer: #{number_to_currency(record.amount, precision: 0)} \nFrom: #{record.giver.name} \nTo: #{record.taker.name} \nYear: #{record.financial_year}"
  end

  def text_for_group(record)
    "Group: #{record.name}"
  end

  def text_for_person(record)
    "Person: #{record.name}"
  end
end