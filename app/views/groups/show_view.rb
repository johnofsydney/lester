class Groups::ShowView < ApplicationView

  attr_reader :group, :depth

  def initialize(group:, depth:)
    @group = group
    @depth = depth
  end

  def template
    page_number = 0

    div(class:"text-center mb-4") do
      render Common::Heading.new(entity: group)

      a(href: "/groups/#{group.id}/network_graph", class:"btn btn-primary btn-lg shadow") do
        strong { 'Explore the Network Graph' }
      end
    end

    comment { "Stats Section" }
    div(class: "row text-center mb-4") do
      div(class: "col-md-4") do
        div(class: "p-3 bg-light rounded shadow-sm equal-height") do
          div(class: 'vertical-centre-value') do
            table_style = (group.money_in.present? && group.money_out.present?) ? "margin-bottom: 1rem;" : "margin-bottom: 0;"
            table(class: "table table-sm  no-border-table", style: table_style) do
              tbody do
                tr do
                  td { "in" }
                  td(class: "h5 fw-bold mb-0") { group.money_in }
                end if group.money_in.present?
                tr do

                  td(class: "h5 fw-bold mb-0") { group.money_out }
                  td { "out" }
                end if group.money_out.present?
              end
            end
          end if group.money_in.present? || group.money_out.present?
          p(class: "text-muted small bottom-text") { "Transfers" }
        end
      end
      div(class: "col-md-4") do
        div(class: "p-3 bg-light rounded shadow-sm equal-height") do
          div(class: 'vertical-centre-value') do
            p(class: "h5 fw-bold mb-0") { group.people.count }
          end
          p(class: "text-muted small bottom-text") { "People in Group" }
        end
      end
      div(class: "col-md-4") do
        div(class: "p-3 bg-light rounded shadow-sm equal-height") do
          div(class: 'vertical-centre-value') do
            p(class: "h5 fw-bold mb-0") { group.affiliated_groups.count }
          end
          p(class: "text-muted small bottom-text") { "Connected Groups" }
        end
      end
    end

    render Common::MoneySummary.new(entity: group)

    turbo_frame(id: 'people', src: "/groups/group_people/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching People...'  }
      hr
    end

    turbo_frame(id: 'affiliated_groups', src: "/groups/affiliated_groups/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching Affiliated Groups...'  }
      hr
    end

    render TransfersTableComponent.new(
    entity: group,
    transfers: group.consolidated_transfers(depth: 0), # <== This is building a table with transfers directly connected to the group
    heading: "Directly Connected to #{group.name}",
    summarise_for: Group.summarise_for(group),
    )

    turbo_frame(id: 'feed', src: lazy_load_group_path, loading: :lazy) do  # <== This is lazy loading a turbo frame
      p(class: 'grey') { 'Fetching More Transfer Records...'}
      hr
    end
  end
end
