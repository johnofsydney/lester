require 'rails_helper'

RSpec.describe Cache::NodeCountJob, type: :job do
  subject(:perform) { described_class.new.perform(klass, id) }

  let(:klass) { 'Group' }

  context 'when the record exists' do
    let(:group) { create(:group) }
    let(:id) { group.id }

    before { allow_any_instance_of(Group).to receive(:nodes).and_return(Group.none) }

    it 'updates nodes_count_cached and nodes_count_cached_at' do
      expect { perform }.to change { group.reload.nodes_count_cached }.to(0)
      expect(group.reload.nodes_count_cached_at).to be_present
    end
  end

  context 'when the record cannot be found' do
    let(:id) { 0 }

    it 'does not raise' do
      expect { perform }.not_to raise_error
    end
  end
end
