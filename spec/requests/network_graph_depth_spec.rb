require 'rails_helper'

RSpec.describe 'Network graph depth selection' do
  let(:person) { create(:person, name: 'Root Person') }

  before do
    allow(Sidekiq::Queue).to receive(:new).and_return(instance_double(Sidekiq::Queue, size: 0))

    person.cached_summary = {
      'consolidated_descendents' => (0..3).map do |depth|
        cached_descendent(id: depth, name: "Node #{depth}", klass: 'Person', depth: depth)
      end
    }
    person.cached_summary_timestamp = Time.zone.now
    person.save!
  end

  it 'only returns nodes up to the requested depth' do
    get "/people/#{person.id}/network_graph", params: { depth: 1 }

    depths = page_prop('json_nodes').map { |node| node['depth'] }

    expect(depths).to contain_exactly(0, 1)
  end

  it 'defaults to depth 2 when no depth is requested' do
    get "/people/#{person.id}/network_graph"

    depths = page_prop('json_nodes').map { |node| node['depth'] }

    expect(depths).to contain_exactly(0, 1, 2)
  end
end
