class InterestingRecords < ApplicationView
  include ActionView::Helpers::NumberHelper

  def initialize(records: nil)
    @records = records
  end

  attr_reader :records

  def template
    h2 { 'Interesting and / or New Records' }
    ul do
      @records.each do |record|
        li do
          a(href: "/transfers/#{record.id}") { text(record) }
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
    "Group: #{record.name} \nNodes: #{record.nodes.count}"
  end

  def text_for_person(record)
    "Person: #{record.name} \nNodes: #{record.nodes.count}"
  end
end