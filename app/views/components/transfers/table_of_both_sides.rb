class Transfers::TableOfBothSides < ApplicationView
  attr_reader :transfer, :depth

	 def initialize(transfer:)
 		@transfer = transfer
   @depth = Constants::MAX_SEARCH_DEPTH
 	end

  def view_template
    div(class: 'row') do
      giver_descendents = transfer.giver.consolidated_descendents(depth:, transfer:)
      taker_descendents = transfer.taker.consolidated_descendents(depth:)

      div(class: 'col', id: 'descendents-of-giver') do
        p do
          plain 'Associated People and Groups of (TODO)'
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
          plain 'Associated People and Groups of '
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
  end
end