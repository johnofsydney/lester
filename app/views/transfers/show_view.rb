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
        p do
          span { 'Evidence: ' }
          a(href: transfer.evidence) { transfer.evidence }
        end
        p do
          span { "Effective Date: #{transfer.effective_date}"}
        end
      end
    end
    div(class: 'row') do
      div(class: 'col', id: 'descendents-of-giver') do
        descendents = transfer.giver.consolidated_descendents(depth:, transfer:)

        p do
          plain "Associated People and Groups of "
          strong {transfer.giver.name}
          plain " (depth: #{depth})"
        end
        table(class: 'table', id: 'giver-table') do
          thead do
            tr do
              th { 'Name' }
              th { 'Depth' }
            end
          end
          tbody do
            descendents.each do |descendent|
              tr(class: "depth-#{descendent.depth}") do
                td { link_for(entity: descendent) }
                td { descendent.depth }
              end
            end
          end
        end
      end
      div(class: 'col', id: 'descendents-of-taker') do
        descendents = transfer.taker.consolidated_descendents(depth:)

        p do
          plain "Associated People and Groups of "
          strong {transfer.taker.name}
          plain " (depth: #{depth})"
        end
        table(class: 'table', id: 'taker-table') do
          thead do
            tr do
              th { 'Name' }
              th { 'Depth' }
            end
          end
          tbody do
            descendents.each do |descendent|
              tr(class: "depth-#{descendent.depth}") do
                td { link_for(entity: descendent) }
                td { descendent.depth }
              end
            end
          end
        end


      end
    end
    if transfer.data.present?
      div(class: 'row') do
        p do
          transfer.data.to_s
        end
      end
    end

    script do
      "console.log(123)"
    end
  end
end