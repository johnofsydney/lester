class Transfers::IndexView < ApplicationView

  attr_reader :transfers

  def initialize(transfers:)
    @transfers = transfers
  end

  def template
    h3 { "Transfers: (#{transfers.count} records)" }
    table(class: 'table') do
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
        transfers.find_each do |transfer|
          tr do
            td do
              if transfer.id
                a(href: "/transfers/#{transfer.id}") { transfer.id}
              else
                "nope"
              end
            end
            td { transfer.amount }
            td { transfer.effective_date.to_s }
            td { transfer.transfer_type }
            td { transfer.giver.name }
            td { transfer.taker.name }
          end
        end
      end
    end
  end
end