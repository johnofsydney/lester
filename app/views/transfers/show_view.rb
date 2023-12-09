class Transfers::ShowView < ApplicationView

  attr_reader :transfer

  def initialize(transfer:)
    @transfer = transfer
  end

  def template
    div(class: 'container') do
      render MenuComponent.new(entity: transfer)

      div(class: 'heading') do
        a(
          href: "/transfers/#{transfer.id}",
          class: 'btn w-100',
          style: button_styles(transfer)
        ) { "$#{transfer.formatted_amount}" }
      end

      div(class: 'row') do
        h2 { "Transfer of #{transfer.formatted_amount} From #{transfer.giver.name} to #{transfer.taker.name}" }
        p do
          span { "Evidence: " }
          a(href: transfer.evidence) {"Evidence: #{transfer.evidence}"}
        end
        p do
          span { "Effective Date: #{transfer.effective_date}"}
        end
      end
      div(class: 'row') do
        div(class: 'col') do
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
                tr(class: "depth-#{descendent.depth}") do
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
                tr(class: "depth-#{descendent.depth}") do
                  td { link_for(entity: descendent) }
                  td { descendent.depth }
                end
              end
            end
          end
        end
      end


    end

    script do
      "console.log(123)"
    end
  end
end