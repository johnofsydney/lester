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
    render Common::Heading.new(entity: group)
    render Common::MoneySummary.new(entity: group)
    render Groups::AffiliatedGroups.new(group:)
    render Groups::People.new(group:)

    render TransfersTableComponent.new(
      entity: group,
      transfers: group.consolidated_transfers(depth: 0),
      heading: "Directly Connected to #{group.name}",
      summarise_for: Group.summarise_for(group)
    )

    turbo_frame(id: 'feed', src: lazy_load_group_path, loading: :lazy) do
      p do
        p { 'Loading More Transfer Records...'}
        hr
      end
    end
  end
end