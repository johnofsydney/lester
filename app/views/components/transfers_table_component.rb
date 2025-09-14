class TransfersTableComponent < ApplicationView
  include ActionView::Helpers::NumberHelper

  def initialize(transfers:, heading:, summarise_for: nil, exclude: nil, entity:, remove_zero_degrees: false)
    # these transfers are already consolidated with depth relative to the entity
    @transfers = remove_zero_degrees ? transfers.select { |t| t.depth > 0 } : transfers
    @heading = heading
    @summarise_for = summarise_for
    @exclude = exclude
    @entity = entity
  end

  attr_reader :transfers, :heading, :summarise_for, :exclude, :entity

  def template
    return nil if transfers.empty?

    return make_table(transfers) if (summarise_for.nil? && exclude.nil?)

    # TODO: also deal with summarise outbound?
    if summarise_for.present?
      transfers_to_summarise = transfers.group_by { |t| [t.taker_name, t.effective_date, t.depth, t.direction, t.taker_id] }
                                        .select { |combo, transfers| summarise_for.include?(combo.first) && transfers.count > 1 }

      summary_rows = transfers_to_summarise.map do |combo, transfers|
        OpenStruct.new(
          giver: OpenStruct.new(name: "#{transfers.count} individual records, from various donors"),
          taker: OpenStruct.new(name: combo.first, id: combo[4], report_as: 'group'),
          amount: transfers.sum(&:amount),
          effective_date: transfers.map(&:effective_date).max,
          depth: combo[2],
          direction: combo[3],
        )
      end

      make_table(transfers - transfers_to_summarise.values.flatten + summary_rows)
    elsif exclude.present?
      transfers_grouped_by_name = transfers.group_by { |t| t.taker.name }
      transfers_grouped_by_each_exclude_name = transfers_grouped_by_name.slice(*exclude)
      make_table(transfers - transfers_grouped_by_each_exclude_name.values.flatten)
    else
      return make_table(transfers)
    end

  end

  def make_table(transfers)
    div(class: 'row mt-3 mb-3') do
      h4(class: 'font-italic') { 'Transfers' }
      p { "#{heading} (#{transfers.count} records)" }
      table(class: 'table responsive-table') do
        tr do
          th { 'ID' }
          th { 'Amount' }
          th { 'Year' }
          th { 'Giver' }
          th { 'Taker' }
          th(class: 'desktop-only') { 'Depth' }
          th(class: 'desktop-only') { 'Direction' }
        end

        transfers.sort_by{ |t| [t.depth, -t.amount] }.each do |transfer|
          tr do
            td(style: row_style(transfer)) do
              if transfer.id
                link_for(entity: transfer, link_text: transfer.id, klass: 'Transfer')
              else
                ''
              end
            end
            td(style: row_style(transfer)) { number_to_currency(transfer.amount.to_s, precision: 0) }
            td(style: row_style(transfer)) { transfer.effective_date.to_date.year.to_s }
            if transfer.giver_id
              td(style: row_style(transfer)) { transfer.giver_name } # { link_for(entity: transfer.giver) if transfer.giver}
            elsif transfer.giver
              td(style: row_style(transfer)) { transfer.giver_name } # only for summary rows
            end

            td(style: row_style(transfer)) { transfer.taker_name } # { link_for(entity: transfer.taker) if transfer.taker}
            td(style: row_style(transfer), class: 'desktop-only') { transfer.depth }
            td(style: row_style(transfer), class: 'desktop-only') { transfer.direction }
          end
        end
      end
    end
  end

  def row_style(transfer)
    return '' unless transfer.depth && transfer.direction

    transparency = 0.7 - (0.1 * transfer.depth)

    if transfer.direction == 'incoming'
      "background-color: rgba(60, 200, 0, #{transparency});"
    elsif transfer.direction == 'outgoing'
      "background-color: rgba(255, 25, 10, #{transparency});"
    end
  end
end
