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
    end
  end

  describe '#color' do
    context 'when the depth is 0' do
      let(:depth) { 0 }

      it { expect(descendent.color).to eq('rgba(240,50,50,1)') }
    end

    context 'when the depth is 1' do
      let(:depth) { 1 }

      it { expect(descendent.color).to eq('rgba(255,180,50,1)') }
    end

    context 'when the depth is 2' do
      let(:depth) { 2 }

      it { expect(descendent.color).to eq('rgba(100,210,80,1)') }
    end

    context 'when the depth is 3' do
      let(:depth) { 3 }

      it { expect(descendent.color).to eq('rgba(90,165,255,1)') }
    end

    context 'when the depth is 4' do
      let(:depth) { 4 }

      it { expect(descendent.color).to eq('rgba(170,90,240,1)') }
    end

    context 'when the depth is 5' do
      let(:depth) { 5 }

      it { expect(descendent.color).to eq('rgba(180,180,180,1)') }
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

  describe '#url' do
    context 'when the klass is Thing' do
      let(:klass) { 'Thing' }
      let(:id) { 1 }

      it { expect(descendent.url).to eq('/things/1') }
    end
  end
end
