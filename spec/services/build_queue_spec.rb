require 'rails_helper'


describe BuildQueue do
  let(:john) { Person.create(name: 'John') }
  let(:paul) { Person.create(name: 'Paul') }
  let(:ben) { Person.create(name: 'Ben') }
  let(:eddie) { Person.create(name: 'Eddie') }

  let(:usyd) { Group.create(name: 'USYD') }
  let(:aloy) { Group.create(name: 'Aloy') }
  let(:alp) { Group.create(name: 'ALP') }

  before do
    Membership.create(person: john, group: usyd, start_date: Date.new(1990, 1, 1), end_date: Date.new(1994, 12, 31))
    Membership.create(person: ben, group: usyd, start_date: Date.new(1989, 1, 1), end_date: Date.new(1993, 12, 31))
    Membership.create(person: paul, group: aloy, start_date: Date.new(1982, 1, 1), end_date: Date.new(1988, 12, 31))
    Membership.create(person: ben, group: aloy, start_date: Date.new(1982, 1, 1), end_date: Date.new(1988, 12, 31))
    Membership.create(person: eddie, group: alp, start_date: Date.new(1972, 1, 1), end_date: Date.new(2014, 12, 31))
    Membership.create(person: john, group: alp, start_date: Date.new(2022, 1, 1))
  end

  let(:queue) { [john] }
  let(:visited_membership_ids) { [] }
  let(:visited_nodes) { [] }
  let(:counter) { 0 }
  let(:build_queue) { described_class.new(queue, visited_membership_ids, visited_nodes, counter) }

  describe '#initialize' do
    it 'initializes with correct attributes' do
      expect(build_queue.queue).to eq(queue)
      expect(build_queue.visited_membership_ids).to eq(visited_membership_ids)
      expect(build_queue.visited_nodes).to eq(visited_nodes)
      expect(build_queue.counter).to eq(counter)
    end
  end

  describe '#call' do
    context 'when queue is empty or nil' do
      let(:queue) { [] }

      it 'returns an empty array' do
        expect(build_queue.call).to eq([])
      end
    end

    context 'when queue is not empty' do


      it 'returns an array of nodes' do
        expect(build_queue.call).to eq(john.nodes)
      end
    end
  end
end