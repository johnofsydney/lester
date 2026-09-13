require 'rails_helper'

RSpec.describe 'Network graph edges' do
  let(:root) { Person.create(name: 'Root Person') }
  let(:capped_party) { Group.create(name: 'Capped Party') }
  let(:unrendered_member) { Person.create(name: 'Unrendered Member') }

  before do
    Membership.create(member: root, group: capped_party)
    Membership.create(member: unrendered_member, group: capped_party)

    root.cached_summary = {
      'consolidated_descendents' => [
        descendent(id: root.id, name: root.name, klass: 'Person', depth: 0),
        descendent(id: capped_party.id, name: capped_party.name, klass: 'Group', depth: 1)
      ]
    }
    root.cached_summary_timestamp = Time.zone.now
    root.save!
  end

  it 'only includes edges whose both endpoints are rendered nodes' do
    get "/people/#{root.id}/network_graph"

    node_ids = page_prop('json_nodes').map { |node| node['id'] }
    edges = page_prop('json_edges')

    expect(edges).to contain_exactly({ 'from' => "group_#{capped_party.id}", 'to' => "person_#{root.id}" })
    expect(edges.flat_map { |edge| edge.values_at('from', 'to') }).to all(be_in(node_ids))
  end

  def descendent(id:, name:, klass:, depth:)
    {
      'parent_id' => nil, 'parent_name' => nil, 'parent_klass' => nil, 'parent_count' => 0,
      'id' => id, 'name' => name, 'klass' => klass, 'depth' => depth,
      'shape' => 'dot', 'color' => 'rgba(0,0,0,1)', 'mass' => 2, 'size' => 5,
      'url' => "/#{klass.downcase.pluralize}/#{id}", 'last_position' => nil, 'is_tag' => false
    }
  end

  def page_prop(key)
    page_props = JSON.parse(response.body[/data-page="([^"]+)"/, 1].gsub('&quot;', '"'))['props']
    JSON.parse(page_props[key])
  end
end
