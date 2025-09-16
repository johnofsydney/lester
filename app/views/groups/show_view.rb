class Groups::ShowView < ApplicationView

  attr_reader :group, :depth

  def initialize(group:, depth:)
    # TODO: push the .cached version further up the stack. stop passing around group
    @group = group
    @depth = depth
  end

  def template
    page_number = 0

    render Common::Heading.new(entity: group)
    render Common::StatsSummary.new(entity: group)
    render Common::GraphSummary.new(entity: group)

    ##################################################
    # TODO: these no longer need to be in turbo frames
    turbo_frame(id: 'people', src: "/groups/group_people/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching People...'  }
    end

    turbo_frame(id: 'affiliated_groups', src: "/groups/affiliated_groups/#{group.id}/page=#{page_number}", loading: :lazy) do
      # raise 'add pagination. reduce queries and counts'
      p(class: 'grey') { 'Fetching Affiliated Groups...'  }
    end
    # TODO: these no longer need to be in turbo frames
    ##################################################

    render TransfersTableComponent.new(
    entity: group,
    transfers: group.cached.consolidated_transfers,
    heading: "Directly Connected to #{group.name}",
    # summarise_for: Group.summarise_for(group), # not required for depth 0 ?
    )
  end
end
