class Groups::ShowView < ApplicationView
  # include ActionView::Helpers::NumberHelper
  # include Phlex::Rails::Helpers::TurboStream
  # include Phlex::Rails::Helpers::TurboStreamFrom
  # include Phlex::Rails::Helpers::TurboFrameTag

  attr_reader :group, :depth

  def initialize(group:, depth:)
    @group = group
    @depth = depth
  end

  def template
    page_number = 0

    render Common::Heading.new(entity: group)
    render Common::MoneySummary.new(entity: group)
    # turbo_frame(id: 'money_summary', src: "/groups/money_summary/#{group.id}", loading: :lazy) do
    #   h4 { 'Fetching Money Summary...'  }
    # end

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
