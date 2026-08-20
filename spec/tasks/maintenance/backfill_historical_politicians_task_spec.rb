require 'rails_helper'

RSpec.describe Maintenance::BackfillHistoricalPoliticiansTask do
  before do
    described_class.instance_variable_set(:@max_person_id, nil)
    allow(OpenAustralia::MaxKnownPersonId).to receive(:call).and_return(5)
  end

  after do
    described_class.instance_variable_set(:@max_person_id, nil)
  end

  describe '.max_person_id' do
    it 'memoizes OpenAustralia::MaxKnownPersonId.call at the class level' do
      described_class.max_person_id
      described_class.max_person_id

      expect(OpenAustralia::MaxKnownPersonId).to have_received(:call).once
    end
  end

  describe '#collection' do
    it 'returns every person_id from 1 up to the max known id, as an Array' do
      task = described_class.new

      expect(task.collection).to eq([1, 2, 3, 4, 5])
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      task = described_class.new
      expect(task.count).to eq(task.collection.size)
    end
  end

  describe '#process' do
    it 'enqueues OpenAustralia::IngestPersonJob with a flat SPACING delay' do
      allow(OpenAustralia::IngestPersonJob).to receive(:perform_in)

      described_class.new.process(3)

      expect(OpenAustralia::IngestPersonJob).to have_received(:perform_in).with(described_class::SPACING, 3)
    end
  end
end
