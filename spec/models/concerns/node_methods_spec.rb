require 'rails_helper'

RSpec.describe NodeMethods do
  # CachedMethods#nodes_count checks Sidekiq::Queue#size (a live Redis call) before deciding
  # whether to enqueue a Cache::NodeCountJob — Sidekiq::Testing.fake! (rails_helper) only fakes
  # perform_async, not this queue-inspection call, so it still hits Redis without this stub.
  before do
    allow(Sidekiq::Queue).to receive(:new).and_return(instance_double(Sidekiq::Queue, size: 0))
    # Cache::NodeCountJob sets sidekiq_options(lock: :until_executed) (sidekiq-unique-jobs), which
    # does its own real Redis lock check on every perform_async call regardless of
    # Sidekiq::Testing.fake! — stub the job directly, matching this codebase's usual pattern for
    # avoiding job side effects in specs (e.g. record_group_spec.rb, tender_ingestor_spec.rb).
    allow(Cache::NodeCountJob).to receive(:perform_async)
  end

  def add_position(membership, title:, start_date: nil, end_date: nil)
    membership.positions.create!(title: title, start_date: start_date, end_date: end_date)
  end

  describe '#direct_connections on a Person' do
    let(:person) { create(:person) }
    let(:group) { create(:group, name: 'australian federal parliament') }

    it 'returns one row per Membership, each with its own Position, not collapsed onto a single one' do
      first_stint = create(:membership, member: person, group: group, start_date: Date.new(2005, 7, 1), end_date: Date.new(2013, 8, 8))
      add_position(first_stint, title: 'Senator (Queensland)', start_date: first_stint.start_date, end_date: first_stint.end_date)

      second_stint = create(:membership, member: person, group: group, start_date: Date.new(2013, 9, 7), end_date: Date.new(2017, 10, 27))
      add_position(second_stint, title: 'MP', start_date: second_stint.start_date, end_date: second_stint.end_date)

      third_stint = create(:membership, member: person, group: group, start_date: Date.new(2017, 12, 2))
      add_position(third_stint, title: 'MP', start_date: third_stint.start_date)

      connections = person.direct_connections
      titles = connections.map { |c| c[:last_position] }

      expect(connections.size).to eq(3)
      expect(titles).to contain_exactly(
        'Senator (Queensland) | (July 2005 - 08/08/2013)',
        'MP | (07/09/2013 - 27/10/2017)',
        'MP | (since 02/12/2017)'
      )
    end

    it 'orders rows by start_date, most recent first' do
      create(:membership, member: person, group: group, start_date: Date.new(2005, 7, 1), end_date: Date.new(2013, 8, 8))
      create(:membership, member: person, group: group, start_date: Date.new(2017, 12, 2))

      memberships_in_order = person.memberships.order(start_date: :desc)

      expect(memberships_in_order.first.start_date).to eq(Date.new(2017, 12, 2))
      expect(memberships_in_order.last.start_date).to eq(Date.new(2005, 7, 1))
      expect(person.direct_connections.size).to eq(2)
    end

    it 'omits last_position when the Membership has no Position' do
      create(:membership, member: person, group: group, start_date: Date.new(2020, 1, 1))

      connection = person.direct_connections.sole

      expect(connection).not_to have_key(:last_position)
    end
  end

  describe '#direct_connections on a Group' do
    let(:group) { create(:group, name: 'nationals (federal)') }

    it 'shows one row per Person, preferring the currently-open Membership over a closed one' do
      person = create(:person, name: 'barnaby joyce')
      closed = create(:membership, member: person, group: group, start_date: Date.new(2005, 7, 1), end_date: Date.new(2013, 8, 8))
      add_position(closed, title: 'Federal Parliamentary Party Member', start_date: closed.start_date, end_date: closed.end_date)

      open = create(:membership, member: person, group: group, start_date: Date.new(2017, 12, 2))
      add_position(open, title: 'Federal Parliamentary Party Member', start_date: open.start_date)

      connections = group.direct_connections.select { |c| c[:klass] == 'Person' }

      expect(connections.size).to eq(1)
      expect(connections.first[:last_position]).to eq('Federal Parliamentary Party Member | (since 02/12/2017)')
    end

    it 'prefers the most recently ended Membership when none are open' do
      person = create(:person)
      earlier = create(:membership, member: person, group: group, start_date: Date.new(2005, 1, 1), end_date: Date.new(2010, 1, 1))
      add_position(earlier, title: 'Party Member', start_date: earlier.start_date, end_date: earlier.end_date)

      later = create(:membership, member: person, group: group, start_date: Date.new(2015, 1, 1), end_date: Date.new(2018, 1, 1))
      add_position(later, title: 'Party Member', start_date: later.start_date, end_date: later.end_date)

      connections = group.direct_connections.select { |c| c[:klass] == 'Person' }

      expect(connections.size).to eq(1)
      expect(connections.first[:last_position]).to eq('Party Member | (January 2015 - January 2018)')
    end

    it 'does not duplicate a Person who has more than one distinct Group in common by accident' do
      person = create(:person)
      other_group = create(:group)
      create(:membership, member: person, group: group)
      create(:membership, member: person, group: other_group)

      connections = group.direct_connections.select { |c| c[:klass] == 'Person' }

      expect(connections.size).to eq(1)
    end

    it 'marks a connection as current when its Membership has no end_date, and not current otherwise' do
      current_person = create(:person, name: 'current person')
      create(:membership, member: current_person, group: group, start_date: Date.new(2020, 1, 1))

      ex_person = create(:person, name: 'ex person')
      create(:membership, member: ex_person, group: group, start_date: Date.new(2010, 1, 1), end_date: Date.new(2015, 1, 1))

      connections = group.direct_connections.select { |c| c[:klass] == 'Person' }.index_by { |c| c[:id] }

      expect(connections[current_person.id][:current]).to be(true)
      expect(connections[ex_person.id][:current]).to be(false)
    end
  end

  describe '#direct_connections group-to-group connections' do
    let(:parent) { create(:group, name: 'a coalition') }
    let(:child) { create(:group, name: 'a subsidiary') }

    it 'shows a sub-group the group owns, via its own memberships association' do
      create(:membership, member: child, group: parent)

      connections = parent.direct_connections.select { |c| c[:klass] == 'Group' }

      expect(connections.map { |c| c[:id] }).to contain_exactly(child.id)
    end

    it 'shows a parent group it belongs to, from the opposite direction' do
      create(:membership, member: child, group: parent)

      connections = child.direct_connections.select { |c| c[:klass] == 'Group' }

      expect(connections.map { |c| c[:id] }).to contain_exactly(parent.id)
    end

    it 'does not duplicate a group connected via more than one non-contiguous Membership' do
      create(:membership, member: child, group: parent, start_date: Date.new(2000, 1, 1), end_date: Date.new(2005, 1, 1))
      create(:membership, member: child, group: parent, start_date: Date.new(2010, 1, 1))

      connections = parent.direct_connections.select { |c| c[:klass] == 'Group' }

      expect(connections.size).to eq(1)
    end

    it 'reports a Tag-type group with klass Tag, preserving STI, when seen from its member Group' do
      tag = Tag.create!(name: 'charities')
      member_group = create(:group)
      create(:membership, member: member_group, group: tag)

      connections = member_group.direct_connections.select { |c| c[:id] == tag.id }

      expect(connections.first[:klass]).to eq('Tag')
    end

    it 'does not raise when a Membership references a Group that no longer exists' do
      create(:membership, member: child, group: parent)
      orphaned_child = create(:group)
      create(:membership, member: orphaned_child, group: parent)
      orphaned_child.delete # bypass dependent: :destroy cleanup to simulate a pre-existing orphaned row

      connections = parent.direct_connections.select { |c| c[:klass] == 'Group' }

      expect(connections.map { |c| c[:id] }).to contain_exactly(child.id)
    end
  end
end
