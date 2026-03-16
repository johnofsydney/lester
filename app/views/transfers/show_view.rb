class Transfers::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :transfer, :depth

  def initialize(transfer:)
    @transfer = transfer
    @depth = 6
  end

  def view_template
    # money summary
    h4 { "Transfer of #{number_to_currency(transfer.amount, precision: 0)} From #{transfer.giver.name} to #{transfer.taker.name}" }

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

    if transfer.individual_transactions.present?
      hr

      p do
        plain "A single 'transfer' can represent multiple single payments in the same financial year. "
        i { 'This '}
        plain 'transfer represents the following payments:'
      end

      table(class: 'table table-striped') do
          thead do
            tr do
              th { 'Payment Type' }

              if transfer.government_contracts?
                th { 'Evidence' }
                th { 'Contract ID' }
                th { 'Amendment ID' }
                th { 'Category' }
              end
              th { 'Description' }
              th(class: 'text-end') { 'Amount' }
              th(class: 'text-end') { 'Date' }
            end
          end
          transfer.individual_transactions.each do |individual_transaction|
            if individual_transaction.government_contract?
              details_type = 'Government Contract'
              truncation_value = 50
            elsif individual_transaction.donation?
              details_type = 'Donation'
              truncation_value = 100
            end
            tbody do
              td { details_type }

              if individual_transaction.government_contract?
                td do
                  a(href: individual_transaction.evidence, target: :_blank) { individual_transaction.evidence.truncate(40) }
                end
                td { individual_transaction.contract_id }
                td { individual_transaction.amendment_id }
                td { individual_transaction.fine_grained_transaction_category.name }
              end
              td(data: { bs_toggle: 'tooltip', bs_title: individual_transaction.description }) do
                individual_transaction.description.truncate(truncation_value)
              end
              td(class: 'text-end') { number_to_currency(individual_transaction.amount, precision: 0) }
              td(class: 'text-end') { individual_transaction.effective_date.strftime('%d %b %Y') }
            end
          end
      end
    end

    if Current.admin_user?
      content_for :admin_sidebar do
        div(
          class: 'admin-links d-none d-lg-flex flex-column align-items-start bg-light ps-4 pe-4 mt-4',
          style: 'min-width: 250px; min-height: 100vh;'
        ) do
          a(href: "/admin/transfers/#{transfer.id}", class: 'btn btn-sm btn-outline-primary mb-2 w-100') { 'Edit Transfer in Admin' }
        end
      end
    end
  end
end
