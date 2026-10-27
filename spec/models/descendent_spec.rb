require 'rails_helper'

RSpec.describe Descendent do
  let(:descendent) { described_class.new(node:, id:, name:, depth:, klass:, parent:, parent_count:) }

  let(:node) { nil }
  let(:id) { nil }
  let(:name) { nil }
  let(:depth) { 1 }
  let(:klass) { nil }
  let(:parent) { nil }
  let(:parent_count) { nil }

  describe '#shape' do
    context 'when the depth is 0' do
      let(:depth) { 0 }

      it { expect(descendent.shape).to eq('circle') }
    end

    context 'when the klass is passed in as a string' do
      context 'and the klass is Person' do
        let(:klass) { 'Person' }

        it { expect(descendent.shape).to eq('dot') }
      end

      context 'and the klass is Group' do
        let(:klass) { 'Group' }

        it { expect(descendent.shape).to eq('box') }
      end
    end

    context 'when the klass has to be calculated' do
      context 'and the node is Person' do
        let(:node) { Person.new(name: 'default_person_name') }

        it { expect(descendent.shape).to eq('dot') }
      end

      context 'and the node is Group' do
        let(:node) { Group.new(name: 'default_group_name') }

        it { expect(descendent.shape).to eq('box') }
      end

      context 'and the node is a capped Group (too large to have been expanded)' do
        let(:node) { instance_double(Group, is_a?: true, nodes_count_cached: 275, id: 1, name: 'liberals (nsw)') }

        it 'uses a distinct shape, not the ordinary box' do
          expect(descendent.shape).to eq('star')
        end
      end

      context 'and the node is a capped Group at depth 0' do
        let(:depth) { 0 }
        let(:node) { instance_double(Group, is_a?: true, nodes_count_cached: 275, id: 1, name: 'liberals (nsw)') }

        it 'stays circle, since the root is exempt from the capped cue' do
          expect(descendent.shape).to eq('circle')
        end
      end
    end
  end

  describe '#color' do
    context 'when the depth is 0 - 5' do
      let(:depth) { 0 }

      it { expect(descendent.color).to match(/rgba\(\d+,\d+,\d+,\d+/) }
    end

    context 'when the depth is 6' do
      let(:depth) { 6 }

      it { expect(descendent.color).to be_nil }
    end
  end

  describe '#mass' do
    context 'when the klass is Person' do
      let(:klass) { 'Person' }

      it { expect(descendent.mass).to eq(2) }
    end

    context 'when parent_count is passed in' do
      context 'and parent_count is 0' do
        let(:parent_count) { 0 }

        it { expect(descendent.mass).to eq(4) }
      end

      context 'and parent_count is 4' do
        let(:parent_count) { 4 }

        it { expect(descendent.mass).to eq(6) }
      end

      context 'and parent_count is 7' do
        let(:parent_count) { 7 }

        it { expect(descendent.mass).to eq(8) }
      end

      context 'and parent_count is 11' do
        let(:parent_count) { 11 }

        it { expect(descendent.mass).to eq(10) }
      end

      context 'and parent_count is greater than 15' do
        let(:parent_count) { 16 }

        it { expect(descendent.mass).to eq(12) }
      end
    end

    context 'when the node is a capped Group leaf (too large to have been expanded)' do
      let(:klass) { 'Group' }
      let(:node) { instance_double(Group, is_a?: true, nodes_count_cached: 275, id: 1, name: 'liberals (nsw)') }

      it 'scales with the leaf\'s own size rather than the usual parent-based tiers' do
        expect(descendent.mass).to eq(15)
      end
    end

    context 'when the node is a Group at depth 0, even if its own size exceeds the cap' do
      let(:depth) { 0 }
      let(:klass) { 'Group' }
      let(:node) { instance_double(Group, is_a?: true, nodes_count_cached: 275, id: 1, name: 'liberals (nsw)') }
      let(:parent_count) { 0 }

      it 'is exempt, since the root always expands regardless of size' do
        expect(descendent.mass).to eq(4)
      end
    end

    context 'when the node is a Group leaf at or under the expand threshold' do
      let(:klass) { 'Group' }
      let(:node) { instance_double(Group, is_a?: true, nodes_count_cached: 50, id: 1, name: 'liberals (nsw)') }
      let(:parent_count) { 0 }

      it 'uses the ordinary parent-based tiers, not the capped scaling' do
        expect(descendent.mass).to eq(4)
      end
    end

    context 'when parent_size is calculated' do
      let(:parent) { instance_double(Group) }

      before do
        allow(parent).to receive(:nodes_count).and_return(parent_count)
      end

      context 'and parent_count is 0' do
        let(:parent_count) { 0 }

        it { expect(descendent.mass).to eq(4) }
      end

      context 'and parent_count is 4' do
        let(:parent_count) { 4 }

        it { expect(descendent.mass).to eq(6) }
      end

      context 'and parent_count is 7' do
        let(:parent_count) { 7 }

        it { expect(descendent.mass).to eq(8) }
      end

      context 'and parent_count is 11' do
        let(:parent_count) { 11 }

        it { expect(descendent.mass).to eq(10) }
      end

      context 'and parent_count is greater than 15' do
        let(:parent_count) { 16 }

        it { expect(descendent.mass).to eq(12) }
      end
    end
  end

  describe '#size' do
    context 'when the depth is 0' do
      let(:depth) { 0 }

      it { expect(descendent.size).to eq(35) }
    end

    context 'when the klass is Person' do
      let(:klass) { 'Person' }

      it { expect(descendent.size).to eq(5) }
    end

    context 'when the klass is a Group' do
      let(:klass) { 'Group' }

      it { expect(descendent.size).to be_nil }
    end
  end

  describe '#to_h' do
    let(:klass) { 'Person' }
    let(:name) { 'adam benson' }
    let(:id) { 1 }
    let(:depth) { 1 }

    it 'capitalizes the name for display' do
      expect(descendent.to_h[:name]).to eq('Adam Benson')
    end

    context 'when there is a parent' do
      let(:parent) { instance_double(Group, id: 2, name: 'abc pty ltd', class: Group, nodes_count: 0) }

      it 'capitalizes the parent name for display' do
        expect(descendent.to_h[:parent_name]).to eq('ABC Pty Ltd')
      end
    end
  end

  describe '#url' do
    context 'when the klass is Thing' do
      let(:klass) { 'Thing' }
      let(:id) { 1 }

      it { expect(descendent.url).to eq('/things/1') }
    end
  end
end
