class Transfers::ShowView < ApplicationView

  attr_reader :transfer

  def initialize(transfer:)
    @transfer = transfer
  end

  def template
    div(class: 'container') do
      div(class: 'row') do
        p { "Transfer of $#{transfer.amount}" }
        p { "From #{transfer.giver.name} to #{transfer.taker.name}" }
        p { "Evidence: #{transfer.evidence}" }
      end
      div(class: 'row') do
        div(class: 'col') do
          p { "From #{transfer.giver.name} to #{transfer.taker.name}" }

          descendents = transfer.giver.consolidated_descendents(depth: 6)

          p { "Associated People and Groups of #{transfer.giver.name}" }
          table(class: 'table') do
            thead do
              tr do
                th { 'Name' }
                th { 'Depth' }
              end
            end
            tbody do
              descendents.each do |descendent|
                tr do
                  td { link_for(entity: descendent) }
                  td { descendent.depth }
                end
              end
            end
          end
        end
        div(class: 'col') do

        end
        div(class: 'col') do
          p { "To #{transfer.taker.name} from #{transfer.giver.name}" }

          descendents = transfer.taker.consolidated_descendents(depth: 6)

          p { "Associated People and Groups of #{transfer.taker.name}" }
          table(class: 'table') do
            thead do
              tr do
                th { 'Name' }
                th { 'Depth' }
              end
            end
            tbody do
              descendents.each do |descendent|
                tr do
                  td { link_for(entity: descendent) }
                  td { descendent.depth }
                end
              end
            end
          end
        end
      end
    end
  end

  def link_for(entity:, class: '')
    a(href: "/#{class_of(entity)}/#{entity.id}", class:) { entity.name }
  end
end