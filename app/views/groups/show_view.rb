class Groups::ShowView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :group

  def initialize(group:)
    # TODO: push the .cached version further up the stack. stop passing around group
    @group = group
  end

  def view_template
    page_number = 0

    render Common::Heading.new(entity: group.cached)

    render Common::StatsSummary.new(
      klass: 'Group',
      direct_connections: group.cached.direct_connections,
      money_in: group.cached.money_in,
      money_out: group.cached.money_out
    )
    render Common::GraphSummary.new(entity: group.cached)

    ##################################################
    # TODO: these no longer need to be in turbo frames
    # all these components need pagination
    turbo_frame(id: 'people', src: "/groups/group_people/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching People...'  }
    end

    turbo_frame(id: 'affiliated_groups', src: "/groups/affiliated_groups/#{group.id}/page=#{page_number}", loading: :lazy) do
      p(class: 'grey') { 'Fetching Affiliated Groups...'  }
    end
    # TODO: these no longer need to be in turbo frames
    ##################################################

    render TransfersTableComponent.new(
      entity: group,
      transfers: group.cached.consolidated_transfers,
      heading: "Connected to #{group.name}",
      summarise_for: Group.summarise_for(group)
    )

    if Current.admin_user?
      content_for :admin_sidebar do
        div(
          class: 'admin-links d-none d-lg-flex flex-column align-items-start bg-light ps-4 pe-4 mt-4',
          style: 'min-width: 250px; min-height: 100vh;'
        ) do
          a(href: "/admin/groups/#{group.id}", class: 'btn btn-sm btn-outline-primary mb-2 w-100') { 'Edit Group in Admin' }
          a(href: "/admin/groups/#{group.id}/merge_with?source_group_id=#{group.id}", class: 'btn btn-sm btn-outline-danger w-100') { 'Merge Group in Admin' }
        end
      end
    end
  end
end
