class Transfers::IndexView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :transfers

  def initialize(transfers:)
    @transfers = transfers
  end

  def template
    h3 { "Transfers: (#{transfers.count} records)" }
    table(class: 'table table-striped responsive-table') do
      thead do
        tr do
          th { 'ID' }
          th { 'Amount' }
          th { 'EOFY Date' }
          th { 'Transfer Type' }
          th { 'Giver Name' }
          th { 'Taker Name' }
        end
      end
      tbody do
        transfers.each do |transfer|
          tr do
            td do
              if transfer.id
                a(href: "/transfers/#{transfer.id}") { transfer.id}
              else
                "nope"
              end
            end
            td { number_to_currency(transfer.amount.to_s, precision: 0) }
            td { transfer.effective_date.strftime('%d/%m/%Y') }
            td { transfer.transfer_type.titleize }
            td { transfer.giver.name if transfer.giver }
            td { transfer.taker.name if transfer.taker }
          end
        end
      end
    end
  end
end
