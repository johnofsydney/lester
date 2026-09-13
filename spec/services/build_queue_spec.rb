require 'rails_helper'

RSpec.describe BuildQueue, type: :service do
  describe '#call' do
    context 'when the queue_node is expandable' do
      let(:councillor) { create(:person, name: 'Councillor') }
      let(:council) { create(:group, name: 'Council') }
      let(:party) { create(:group, name: 'Large Party') }

      before do
        create(:membership, member: councillor, group: council)
        create(:membership, member: councillor, group: party)
      end

      it 'returns all of its connected nodes, regardless of their own size' do
        build_queue = described_class.new([councillor], [], [], 0)

        expect(build_queue.call).to contain_exactly(council, party)
      end
    end

    context 'when the queue_node itself is too large to expand' do
      let(:large_party) { create(:group, name: 'Large Party') }

      before do
        (Constants::MAX_NODES_TO_EXPAND + 1).times do
          create(:membership, member: create(:person), group: large_party)
        end
      end

      it 'does not enumerate its members' do
        build_queue = described_class.new([large_party], [], [], 1)

        expect(build_queue.call).to eq([])
      end

      it 'enumerates its members when it is the root of the traversal' do
        build_queue = described_class.new([large_party], [], [], 0)

        expect(build_queue.call.size).to eq(Constants::MAX_NODES_TO_EXPAND + 1)
      end
    end
  end
end
