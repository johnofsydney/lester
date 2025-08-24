class Groups::ShowView < ApplicationView

  attr_reader :group, :depth

  def initialize(group:, depth:)
    @group = group
    @depth = depth
  end

  def template
    page_number = 0

    render Common::Heading.new(entity: group)
    render Common::StatsSummary.new(entity: group)
    render Common::GraphSummary.new(entity: group)

    turbo_frame(id: 'people', src: "/groups/group_people/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching People...'  }
    end

    turbo_frame(id: 'affiliated_groups', src: "/groups/affiliated_groups/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching Affiliated Groups...'  }
    end

    render TransfersTableComponent.new(
    entity: group,
    transfers: group.consolidated_transfers(depth: 0), # <== This is building a table with transfers directly connected to the group. Let's make a method for direct transfers where depth == 0
    heading: "Directly Connected to #{group.name}",
    summarise_for: Group.summarise_for(group),
    )

    turbo_frame(id: 'feed', src: lazy_load_group_path, loading: :lazy) do  # <== This is lazy loading a turbo frame for indirect transfers as well
      p(class: 'grey') { 'Fetching More Transfer Records...'}
    end
  end
end
