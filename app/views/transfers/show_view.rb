class Transfers::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :transfer, :depth

  def initialize(transfer:)
    @transfer = transfer
    @depth = 6
  end

  def template
    div(class: 'heading') do
      a(
        href: "/transfers/#{transfer.id}",
        class: 'btn w-100',
        style: button_styles(transfer)
      ) { number_to_currency(transfer.amount, precision: 0) }
    end

    div(class: 'row') do
      h2 { "Transfer of #{number_to_currency(transfer.amount, precision: 0)} From #{transfer.giver.name} to #{transfer.taker.name}" }

      div(class: 'row') do
        p do
          span { 'From: ' }
          link_for(entity: transfer.giver)
        end
        p do
          span { 'To: ' }
          link_for(entity: transfer.taker)
        end
        p(class: 'text-truncate') do
          span { 'Evidence: ' }
          a(href: transfer.evidence) { transfer.evidence }
        end
        p do
          span { "Effective Date: #{transfer.effective_date}"}
        end
      end
    end
    div(class: 'row') do
      giver_descendents = transfer.giver.consolidated_descendents(depth:, transfer:)
      taker_descendents = transfer.taker.consolidated_descendents(depth:)

      div(class: 'col', id: 'descendents-of-giver') do
        p do
          plain "Associated People and Groups of "
          br
          strong {transfer.giver.name}
          plain " (depth: #{depth})"
        end
        table(class: 'table', id: 'giver-table') do
          thead do
            tr do
              th { 'Name' }
              th(class: 'text-end') { 'Depth' }
            end
          end
          tbody do
            giver_descendents.each do |descendent|
              tr(class: "depth-#{descendent.depth}") do
                td { link_for(entity: descendent) }
                td(class: 'text-end') { descendent.depth }
              end
            end
          end
        end
      end

      div(class: 'col', id: 'descendents-of-taker') do
        p do
          plain "Associated People and Groups of "
          br
          strong {transfer.taker.name}
          plain " (depth: #{depth})"
        end
        table(class: 'table', id: 'taker-table') do
          thead do
            tr do
              th { 'Name' }
              th(class: 'text-end') { 'Depth' }
            end
          end
          tbody do
            taker_descendents.each do |descendent|
              tr(class: "depth-#{descendent.depth}") do
                td { link_for(entity: descendent) }
                td(class: 'text-end') { descendent.depth }
              end
            end
          end
        end


      end
    end
    if transfer.data.present?
      div(class: 'row') do

        h4 do
          "A single 'transfer' can represent multiple single payments. This transfer represents the following payments:"
        end

        table(class: 'table table-striped') do
          thead do
            tr do
              th { 'Payment Type' }
              th(class: 'text-end') { 'Amount' }
              th(class: 'text-end') { 'Date' }
            end
          end
          transfer.data['donations'].each do |donation|
            tbody do
              td { donation['transfer_type'] }
              td(class: 'text-end') { number_to_currency(donation['amount'], precision: 0) }
              td(class: 'text-end') { donation['donation_date'] }
            end
          end
        end
      end
    end
  end
end