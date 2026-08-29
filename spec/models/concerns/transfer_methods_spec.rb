require 'rails_helper'

RSpec.describe TransferMethods do
  describe '#consolidated_descendents' do
    context 'when the traversal budget is exhausted' do
      let(:root) { Person.create(name: 'Root') }
      let(:group_a) { Group.create(name: 'Group A') }
      let(:group_b) { Group.create(name: 'Group B') }
      let(:other_person) { Person.create(name: 'Other Person') }

      before do
        stub_const('Constants::TRAVERSAL_BUDGET', 2)

        Membership.create(member: root, group: group_a)
        Membership.create(member: root, group: group_b)
        Membership.create(member: other_person, group: group_a)
      end

      it 'stops the whole traversal without expanding into the next depth' do
        descendents = root.consolidated_descendents(depth: 4)

        expect(descendents.map(&:name)).not_to include(other_person.name)
      end
    end
  end
end
