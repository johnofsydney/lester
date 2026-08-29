require 'rails_helper'

RSpec.describe CanAddToQueue do
  describe '.call' do
    context 'when node is a small Tag' do
      let(:tag) { Tag.create(name: 'Coalition', type: 'Tag') }

      before do
        Membership.create(member: Person.create(name: 'Person 1'), group: tag)
      end

      it 'can be expanded' do
        expect(described_class.call(tag, 0)).to be(true)
      end
    end

    context 'when node has more members than MAX_NODES_TO_EXPAND' do
      let(:large_group) { Group.create(name: 'Large Group') }

      before do
        (Constants::MAX_NODES_TO_EXPAND + 1).times do |n|
          Membership.create(member: Person.create(name: "Person #{n}"), group: large_group)
        end
      end

      it 'cannot be expanded' do
        expect(described_class.call(large_group, 0)).to be(false)
      end
    end

    context 'when counter is high but node is small' do
      let(:small_group) { Group.create(name: 'Small Group') }

      before do
        Membership.create(member: Person.create(name: 'Person 1'), group: small_group)
      end

      it 'can be expanded' do
        expect(described_class.call(small_group, 1000)).to be(true)
      end
    end
  end
end
