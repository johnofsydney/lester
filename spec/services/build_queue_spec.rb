require 'rails_helper'

RSpec.describe BuildQueue do
  describe '#call' do
    context 'when the queue_node is expandable' do
      let(:councillor) { Person.create(name: 'Councillor') }
      let(:council) { Group.create(name: 'Council') }
      let(:party) { Group.create(name: 'Large Party') }

      before do
        Membership.create(member: councillor, group: council)
        Membership.create(member: councillor, group: party)
      end

      it 'returns all of its connected nodes, regardless of their own size' do
        build_queue = described_class.new([councillor], [], [], 0)

        expect(build_queue.call).to contain_exactly(council, party)
      end
    end

    context 'when the queue_node itself is too large to expand' do
      let(:large_party) { Group.create(name: 'Large Party') }

      before do
        (Constants::MAX_NODES_TO_EXPAND + 1).times do |n|
          Membership.create(member: Person.create(name: "Person #{n}"), group: large_party)
        end
      end

      it 'does not enumerate its members' do
        build_queue = described_class.new([large_party], [], [], 0)

        expect(build_queue.call).to eq([])
      end
    end
  end
end
