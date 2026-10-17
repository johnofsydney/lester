require 'rails_helper'

RSpec.describe Cache::BuildGroupCachedDataJob, type: :job do
  describe '#perform' do
    it 'refreshes the cached data for the group' do
      group = create(:group)
      allow(Group).to receive(:find_by).with(id: group.id).and_return(group)
      allow(group).to receive(:refresh_cached_data!)

      described_class.new.perform(group.id)

      expect(group).to have_received(:refresh_cached_data!)
    end

    it 'does nothing when the group no longer exists' do
      expect { described_class.new.perform(-1) }.not_to raise_error
    end
  end
end
