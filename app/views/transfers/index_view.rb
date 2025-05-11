class Transfers::IndexView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :transfers, :page, :session, :pages

  def initialize(transfers:, page:, pages:, session:)
    @transfers = transfers
    @page = page
    @pages = pages
    @session = session
  end

  def template
    h2 { 'Transfers' }

    form(action: '/transfers', enctype: 'multipart/form-data', method: 'get', class: 'row g-3') do
      div(class: 'col-12 col-md-auto') do
        label(for: 'duration_start', class: 'form-label  label-row') { 'Earliest Financial Year (ending in)' }
      end
      div(class: 'col-12 col-md-auto') do
        select(name: 'duration_start', class: 'form-select') do
          Transfer.financial_years.each do |year|
            selected_year = if session[:duration_start].present?
              if session[:duration_start].is_a?(String)
                Date.parse(session[:duration_start]).year
              else
                session[:duration_start].year
              end
            end

            option(
              value: year,
              selected: year == selected_year
            ) { year.to_s }
          end
        end
      end
      div(class: 'col-12 col-md-auto') do
        label(for: 'duration_end', class: 'form-label  label-row') { 'Last Financial Year (ending in)' }
      end
      div(class: 'col-12 col-md-auto') do
        select(name: 'duration_end', class: 'form-select') do
          Transfer.financial_years.each do |year|
            selected_year = if session[:duration_end].present?
              if session[:duration_end].is_a?(String)
                Date.parse(session[:duration_end]).year
              else
                session[:duration_end].year
              end
            end

            option(
              value: year,
              selected: year == selected_year
            ) { year.to_s }
          end
        end
      end
      div(class: 'col-12 col-md-auto') do
        button(class: 'btn btn-primary', type: 'submit') { 'Go!' }
      end
    end

    render Common::PageNav.new(pages: @pages, page: @page, klass: 'transfer')

    table(class: 'table table-striped responsive-table') do

      table_heading

      tbody do
        transfers.each do |transfer|
          tr do
            td do
              if transfer.id
                a(href: "/transfers/#{transfer.id}") { transfer.id}
              else
                'nope'
              end
            end
            td { number_to_currency(transfer.amount.to_s, precision: 0) }
            td { transfer.effective_date.strftime('%d/%m/%Y') }
            td { transfer.transfer_type.titleize }
            td do
              a(href: "/#{transfer.giver_type.downcase.pluralize}/#{transfer.giver_id}") { transfer.giver_name }
            end
            td do
              a(href: "/#{transfer.taker_type.downcase.pluralize}/#{transfer.taker_id}") { transfer.taker_name }
            end
          end
        end
      end
    end
  end

  def table_heading
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
  end

  def selected_start_year(year)
    return false if session[:duration_start].blank?

    session[:duration_start].is_a?(String) || year == session[:duration_start].year
  end

  def selected_end_year(year)
    return false if session[:duration_end].blank?

    if session[:duration_end].is_a?(String)
      Date.parse(session[:duration_end]).year == year
    else
      year == session[:duration_end].year
    end
  end
end
