require 'rails_helper'

RSpec.describe 'Network graph edges' do
  let(:root) { create(:person, name: 'Root Person') }
  let(:capped_party) { create(:group, name: 'Capped Party') }
  let(:unrendered_member) { create(:person, name: 'Unrendered Member') }

  before do
    create(:membership, member: root, group: capped_party)
    create(:membership, member: unrendered_member, group: capped_party)

    root.cached_summary = {
      'consolidated_descendents' => [
        cached_descendent(id: root.id, name: root.name, klass: 'Person', depth: 0),
        cached_descendent(id: capped_party.id, name: capped_party.name, klass: 'Group', depth: 1)
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
end
