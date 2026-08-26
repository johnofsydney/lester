require 'rails_helper'

RSpec.describe Maintenance::CleanupLegacyNswStatePoliticiansTask do
  let!(:nsw_parliament) { FactoryBot.create(:group, name: 'nsw parliament') }

  before { allow(Group).to receive(:nsw_parliament).and_return(nsw_parliament) }

  describe '#collection' do
    it 'includes every Membership in the NSW Parliament Group, and none outside it' do
      membership = FactoryBot.create(:membership, group: nsw_parliament, member: FactoryBot.create(:person))
      FactoryBot.create(:membership, group: FactoryBot.create(:group), member: FactoryBot.create(:person))

      expect(described_class.collection).to contain_exactly(membership)
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      FactoryBot.create(:membership, group: nsw_parliament, member: FactoryBot.create(:person))

      expect(described_class.count).to eq(1)
    end
  end

  describe '#process' do
    context 'when dry_run is true (default)' do
      let(:person) { FactoryBot.create(:person) }
      let!(:membership) { FactoryBot.create(:membership, group: nsw_parliament, member: person) }

      it 'does not delete the Membership or the Person' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        expect { task.process(membership) }.not_to change(Membership, :count)
        expect(Person.exists?(person.id)).to be(true)
      end
    end

    context 'when dry_run is false' do
      let(:task) { described_class.new.tap { |t| t.dry_run = false } }

      context 'for a person whose only Membership is this NSW Parliament one' do
        let(:person) { FactoryBot.create(:person) }
        let!(:membership) { FactoryBot.create(:membership, group: nsw_parliament, member: person) }

        it 'deletes the Membership' do
          expect { task.process(membership) }.to change(Membership, :count).by(-1)
        end

        it 'deletes the Positions attached to the Membership' do
          position = membership.positions.create!(title: 'Member of the Legislative Assembly')

          task.process(membership)

          expect(Position.exists?(position.id)).to be(false)
        end

        it 'deletes the now-orphaned Person' do
          task.process(membership)

          expect(Person.exists?(person.id)).to be(false)
        end
      end

      context 'for a person who also has a party Membership (not orphaned)' do
        let(:person) { FactoryBot.create(:person) }
        let!(:membership) { FactoryBot.create(:membership, group: nsw_parliament, member: person) }
        let!(:party_membership) { FactoryBot.create(:membership, group: FactoryBot.create(:group, name: 'alp (nsw)'), member: person) }

        it 'deletes the Parliament Membership but leaves the Person alone' do
          task.process(membership)

          expect(Person.exists?(person.id)).to be(true)
          expect(Membership.exists?(party_membership.id)).to be(true)
        end
      end

      context 'for a Group member (not a Person)' do
        let(:member_group) { FactoryBot.create(:group) }
        let!(:membership) { FactoryBot.create(:membership, group: nsw_parliament, member: member_group, member_type: 'Group') }

        it 'deletes the Membership without attempting to treat the Group as an orphaned Person' do
          expect { task.process(membership) }.not_to raise_error
          expect(Membership.exists?(membership.id)).to be(false)
          expect(Group.exists?(member_group.id)).to be(true)
        end
      end
    end
  end
end
