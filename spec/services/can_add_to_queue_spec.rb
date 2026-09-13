require 'rails_helper'

RSpec.describe CanAddToQueue, type: :service do
  describe '.call' do
    context 'when node is a small Tag' do
      let(:tag) { Tag.create(name: 'Coalition', type: 'Tag') }

      before do
        create(:membership, member: create(:person), group: tag)
      end

      it 'can be expanded' do
        expect(described_class.call(tag)).to be(true)
      end
    end

    context 'when node has more members than MAX_NODES_TO_EXPAND' do
      let(:large_group) { create(:group, name: 'Large Group') }

      before do
        (Constants::MAX_NODES_TO_EXPAND + 1).times do
          create(:membership, member: create(:person), group: large_group)
        end
      end

      it 'cannot be expanded' do
        expect(described_class.call(large_group)).to be(false)
      end
    end

    context 'when node is a small plain Group' do
      let(:small_group) { create(:group, name: 'Small Group') }

      before do
        create(:membership, member: create(:person), group: small_group)
      end

      it 'can be expanded' do
        expect(described_class.call(small_group)).to be(true)
      end
    end
  end
end
