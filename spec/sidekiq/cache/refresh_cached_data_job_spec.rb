require 'rails_helper'

RSpec.describe Cache::RefreshCachedDataJob, type: :job do
  before { allow(Exports::UploadKeyContentsJob).to receive(:perform_async) }

  describe '#perform' do
    it 'stores the result of to_h and marks the cache fresh' do
      person = create(:person)
      allow(person).to receive(:to_h).and_return({ 'money_in' => 100 })
      allow(Person).to receive(:find_by).with(id: person.id).and_return(person)

      described_class.new.perform('Person', person.id)

      expect(person.reload.cached_summary).to eq({ 'money_in' => 100 })
      expect(person.cache_fresh?).to be true
    end

    it 'uploads the refreshed summary to S3, keyed by class, name and id' do
      person = create(:person, name: 'Jane Donor')
      allow(person).to receive(:to_h).and_return({ 'money_in' => 100 })
      allow(Person).to receive(:find_by).with(id: person.id).and_return(person)

      described_class.new.perform('Person', person.id)

      expect(Exports::UploadKeyContentsJob).to have_received(:perform_async)
        .with("person/#{person.name}_#{person.id}.json", { 'money_in' => 100 }.to_json)
    end

    it 'does nothing when the record no longer exists' do
      expect { described_class.new.perform('Person', -1) }.not_to raise_error
      expect(Exports::UploadKeyContentsJob).not_to have_received(:perform_async)
    end

    it 'rescues and logs instead of raising when to_h fails, identifying the record by class and id' do
      person = create(:person)
      allow(person).to receive(:to_h).and_raise(StandardError, 'boom')
      allow(Person).to receive(:find_by).with(id: person.id).and_return(person)
      allow(Rails.logger).to receive(:error)

      expect { described_class.new.perform('Person', person.id) }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with("Error building cached data for Person ID #{person.id}: boom")
      expect(Exports::UploadKeyContentsJob).not_to have_received(:perform_async)
    end

    it 'works the same way for a group' do
      group = create(:group)
      allow(group).to receive(:to_h).and_return({ 'money_out' => 50 })
      allow(Group).to receive(:find_by).with(id: group.id).and_return(group)

      described_class.new.perform('Group', group.id)

      expect(group.reload.cached_summary).to eq({ 'money_out' => 50 })
      expect(Exports::UploadKeyContentsJob).to have_received(:perform_async)
        .with("group/#{group.name}_#{group.id}.json", { 'money_out' => 50 }.to_json)
    end
  end
end
