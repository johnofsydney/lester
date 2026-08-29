require 'rails_helper'

RSpec.describe 'Network graph depth selection' do
  let(:person) { Person.create(name: 'Root Person') }

  let(:descendent_at_depth) do
    lambda do |depth|
      {
        'parent_id' => nil, 'parent_name' => nil, 'parent_klass' => nil, 'parent_count' => 0,
        'id' => depth, 'name' => "Node #{depth}", 'klass' => 'Person', 'depth' => depth,
        'shape' => 'dot', 'color' => 'rgba(0,0,0,1)', 'mass' => 2, 'size' => 5,
        'url' => "/people/#{depth}", 'last_position' => nil, 'is_tag' => false
      }
    end
  end

  before do
    person.cached_summary = {
      'consolidated_descendents' => (0..3).map { |depth| descendent_at_depth.call(depth) }
    }
    person.cached_summary_timestamp = Time.zone.now
    person.save!
  end

  it 'only returns nodes up to the requested depth' do
    get "/people/#{person.id}/network_graph", params: { depth: 1 }

    depths = requested_node_depths

    expect(depths).to contain_exactly(0, 1)
  end

  it 'defaults to depth 2 when no depth is requested' do
    get "/people/#{person.id}/network_graph"

    depths = requested_node_depths

    expect(depths).to contain_exactly(0, 1, 2)
  end

  def requested_node_depths
    page_props = JSON.parse(response.body[/data-page="([^"]+)"/, 1].gsub('&quot;', '"'))['props']
    JSON.parse(page_props['json_nodes']).map { |n| n['depth'] }
  end
end
