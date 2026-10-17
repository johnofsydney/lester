require 'rails_helper'

RSpec.describe Cache::BuildPersonCachedDataJob, type: :job do
  describe '#perform' do
    it 'refreshes the cached data for the person' do
      person = create(:person)
      allow(Person).to receive(:find_by).with(id: person.id).and_return(person)
      allow(person).to receive(:refresh_cached_data!)

      described_class.new.perform(person.id)

      expect(person).to have_received(:refresh_cached_data!)
    end

    it 'does nothing when the person no longer exists' do
      expect { described_class.new.perform(-1) }.not_to raise_error
    end
  end
end
