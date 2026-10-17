require 'rails_helper'

RSpec.describe Maintenance::IngestNswLcElectionResultsTask do
  describe '#collection' do
    it 'includes SG2301' do
      expect(described_class.collection).to include('SG2301')
    end

    it 'excludes SG1901 (broken for both houses until issue #391 is resolved)' do
      expect(described_class.collection).not_to include('SG1901')
    end
  end

  describe '#count' do
    it 'matches the size of the collection' do
      expect(described_class.count).to eq(described_class.collection.size)
    end
  end

  describe '#process' do
    before { allow(NswStatePoliticians::IngestLcElectionResultsJob).to receive(:perform_async) }

    context 'when dry_run is true (default)' do
      it 'does not enqueue the ingest job' do
        task = described_class.new
        expect(task.dry_run).to be(true)

        task.process('SG2301')

        expect(NswStatePoliticians::IngestLcElectionResultsJob).not_to have_received(:perform_async)
      end
    end

    context 'when dry_run is false' do
      it 'enqueues the ingest job for the given event' do
        task = described_class.new.tap { |t| t.dry_run = false }

        task.process('SG2301')

        expect(NswStatePoliticians::IngestLcElectionResultsJob).to have_received(:perform_async).with('SG2301')
      end
    end
  end
end
