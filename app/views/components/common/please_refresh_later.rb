class Common::PleaseRefreshLater < ApplicationView
  attr_reader :entity

  def initialize(entity:)
    @entity = entity
  end

  def view_template
    # This turbo stream ensures that this page is listening for updates to the entity.
    # An update to the entity will trigger a turbo stream update to this page, which will cause the whole page to refresh
    # which routes hrough the controller as normal, checking the cache freshness and rendering the appropriate view.
    turbo_cable_stream_source(
      channel: 'Turbo::StreamsChannel',
      signed_stream_name: Turbo::StreamsChannel.signed_stream_name(entity)
    )

    div(class: 'alert alert-info text-center') do
      p { 'This data is being prepared. Please refresh this page in a moment to see the updated information.' }
    end
  end
end
