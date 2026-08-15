require 'rails_helper'

RSpec.describe Maintenance::DedupeLobbyistPeopleTask do
  let!(:lobbyists_tag) { Group.create(name: 'Lobbyists') }
  let!(:firm) { Group.create(name: 'Firm A') }

  let!(:keeper) { Person.create(name: 'Adam Benson') }
  let!(:dup1) { Person.create(name: 'Adam Benson') }
  let!(:dup2) { Person.create(name: 'Adam Benson') }
  let!(:unrelated) { Person.create(name: 'Solo Lobbyist') }

  before do
    [keeper, dup1, dup2, unrelated].each do |person|
      Membership.create(group: lobbyists_tag, member: person)
      Membership.create(group: firm, member: person)
    end

    allow(Group).to receive(:lobbyists_tag).and_return(lobbyists_tag)
    allow(Cache::BuildPersonCachedDataJob).to receive(:perform_async)
    allow(Cache::BuildGroupCachedDataJob).to receive(:perform_async)
  end

  describe '#collection' do
    it 'includes every duplicate except the lowest-id keeper for each name' do
      expect(described_class.collection).to contain_exactly(dup1, dup2)
    end

    it 'excludes people who are not tagged as a lobbyist' do
      outsider_dup = Person.create(name: 'Adam Benson')
      Membership.create(group: firm, member: outsider_dup)
      Membership.create(group: Group.create(name: 'Other Group'), member: outsider_dup)

      expect(described_class.collection).not_to include(outsider_dup)
    end

    it 'includes same-name lobbyists even when their employers are disjoint, for manual review' do
      firm_b = Group.create(name: 'Firm B')
      disjoint_dup = Person.create(name: 'Adam Benson')
      Membership.create(group: lobbyists_tag, member: disjoint_dup)
      Membership.create(group: firm_b, member: disjoint_dup)

      expect(described_class.collection).to include(disjoint_dup)
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      expect(described_class.count).to eq(2)
    end
  end

  describe '#process' do
    context 'when dry_run is true (default)' do
      it 'does not merge or destroy anyone' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        expect { task.process(dup1) }.not_to change(Person, :count)
        expect(Person.exists?(dup1.id)).to be(true)
      end
    end

    context 'when dry_run is false' do
      it 'merges the duplicate into the lowest-id keeper' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(dup1) }.to change(Person, :count).by(-1)
        expect(Person.exists?(keeper.id)).to be(true)
        expect(Person.exists?(dup1.id)).to be(false)
      end

      it 'is safe to process the same element twice' do
        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(dup1)

        expect { task.process(dup1) }.not_to raise_error
        expect(Person.exists?(keeper.id)).to be(true)
      end

      it 'leaves unrelated people untouched' do
        task = described_class.new.tap { |t| t.dry_run = false }

        expect { task.process(dup1) }.not_to(change { Person.exists?(unrelated.id) })
      end

      it 'does not merge into a lower-id same-name person who is not tagged as a lobbyist' do
        outsider = Person.create!(name: 'Zeta Yardley')
        Membership.create!(group: firm, member: outsider)
        Membership.create!(group: Group.create!(name: 'Other Group'), member: outsider)

        in_scope_keeper = Person.create!(name: 'Zeta Yardley')
        in_scope_dup = Person.create!(name: 'Zeta Yardley')
        [in_scope_keeper, in_scope_dup].each do |person|
          Membership.create!(group: lobbyists_tag, member: person)
          Membership.create!(group: firm, member: person)
        end
        expect(outsider.id).to be < in_scope_keeper.id

        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(in_scope_dup)

        expect(Person.exists?(outsider.id)).to be(true)
        expect(Person.exists?(in_scope_keeper.id)).to be(true)
        expect(Person.exists?(in_scope_dup.id)).to be(false)
      end

      it 'does not merge same-name lobbyists whose employers are disjoint, leaving them for manual review' do
        firm_b = Group.create!(name: 'Firm B')

        keeper_only = Person.create!(name: 'Casey Nguyen')
        Membership.create!(group: lobbyists_tag, member: keeper_only)
        Membership.create!(group: firm, member: keeper_only)

        disjoint_dup = Person.create!(name: 'Casey Nguyen')
        Membership.create!(group: lobbyists_tag, member: disjoint_dup)
        Membership.create!(group: firm_b, member: disjoint_dup)

        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(disjoint_dup)

        expect(Person.exists?(keeper_only.id)).to be(true)
        expect(Person.exists?(disjoint_dup.id)).to be(true)
      end

      it 'merges a same-name lobbyist with no other memberships into any same-name lobbyist' do
        keeper_only = Person.create!(name: 'Riley Chen')
        Membership.create!(group: lobbyists_tag, member: keeper_only)
        Membership.create!(group: firm, member: keeper_only)

        bare_dup = Person.create!(name: 'Riley Chen')
        Membership.create!(group: lobbyists_tag, member: bare_dup)

        task = described_class.new.tap { |t| t.dry_run = false }
        task.process(bare_dup)

        expect(Person.exists?(keeper_only.id)).to be(true)
        expect(Person.exists?(bare_dup.id)).to be(false)
      end
    end
  end
end
