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
          if transfer.transfer_type == 'Government Contracts'
            heading_one = 'Contract ID'
            heading_two = 'Amendment ID'
          elsif transfer.transfer_type == 'Australian Political Donations'
            heading_one = 'Return ID'
            heading_two = 'Registration Code'
          end

          thead do
            tr do
              th { 'Payment Type' }
              th { 'Evidence' }
              th { heading_one }
              th { heading_two }
              th { 'Description' }
              th(class: 'text-end') { 'Amount' }
              th(class: 'text-end') { 'Date' }
              th(class: 'text-end') { 'Category' } if transfer.transfer_type == 'Government Contract(s)'
            end
          end
          transfer.individual_transactions.each do |individual_transaction|
            if individual_transaction.transaction_type == 'Government Contract'
              details_type = 'Government Contract'
              details_one = individual_transaction.contract_id
              details_two = individual_transaction.amendment_id
            elsif individual_transaction.transaction_type == 'Australian Political Donation'
              details_type = 'Donation'
              details_one = individual_transaction.return_id
              details_two = individual_transaction.registration_code
            end
            tbody do
              td { details_type }
              td do
                a(href: individual_transaction.evidence, target: :_blank) { individual_transaction.evidence.truncate(40) }
              end
              td { details_one }
              td { details_two }
              td { individual_transaction.description.truncate(50) }
              td(class: 'text-end') { number_to_currency(individual_transaction.amount, precision: 0) }
              td(class: 'text-end') { individual_transaction.effective_date.strftime('%d %b %Y') }
              td(class: 'text-end') { individual_transaction.fine_grained_transaction_category.name } if transfer.transfer_type == 'Government Contract(s)'
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
