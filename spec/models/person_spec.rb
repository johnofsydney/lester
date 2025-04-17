# FILEPATH: /Users/john/Projects/John/sunshine_01/spec/models/person_spec.rb
require 'rails_helper'

RSpec.describe Person do
  let(:person) { described_class.new }
  let(:group) { Group.new }
  let(:transfer) { Transfer.new }

  describe '#nodes' do
    xit 'returns groups when include_looser_nodes is false' do
      person.groups << group
      expect(person.nodes).to eq([group])
    end

    xit 'returns groups and other_edge_ends when include_looser_nodes is true' do
      person.groups << group
      person.outgoing_transfers << transfer
      expect(person.nodes(include_looser_nodes: true)).to include(group, transfer.taker)
    end
  end

  describe '#transfers' do
    xit 'returns incoming and outgoing transfers' do
      incoming_transfer = Transfer.create(taker: person)
      outgoing_transfer = Transfer.create(giver: person, giver_type: 'Person')
      expect(person.transfers.incoming).to include(incoming_transfer)
      expect(person.transfers.outgoing).to include(outgoing_transfer)
    end
  end

  describe '#other_edge_ends' do
    xit 'returns takers of outgoing transfers' do
      outgoing_transfer = Transfer.create(giver: person, giver_type: 'Person')
      expect(person.other_edge_ends).to include(outgoing_transfer.taker)
    end
  end
end