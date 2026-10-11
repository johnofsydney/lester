require 'rails_helper'

RSpec.describe Councils::Qld::IngestElectionResultsJob, type: :job do
  describe '#perform' do
    before do
      allow(Councils::Qld::ImportElectionResultsJob).to receive(:perform_in)
    end

    context 'when the elections index has local elections' do
      before do
        allow(Councils::Qld::Elections).to receive(:local).and_return(
          [{ stub: 'lga2020' }, { stub: '2024QLGE' }, { stub: 'MSC24' }]
        )
      end

      it 'enqueues an import job for every local election found, spaced apart' do
        described_class.new.perform

        expect(Councils::Qld::ImportElectionResultsJob).to have_received(:perform_in).with(kind_of(ActiveSupport::Duration), 'lga2020')
        expect(Councils::Qld::ImportElectionResultsJob).to have_received(:perform_in).with(kind_of(ActiveSupport::Duration), '2024QLGE')
        expect(Councils::Qld::ImportElectionResultsJob).to have_received(:perform_in).with(kind_of(ActiveSupport::Duration), 'MSC24')
      end
    end

    context 'when the elections index has no local elections' do
      before { allow(Councils::Qld::Elections).to receive(:local).and_return([]) }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform }.to raise_error(RuntimeError, /No QLD local elections found/)
        expect(IngestSourceStatus.find_by(key: described_class.name).last_failure_at).to be_present
        expect(Councils::Qld::ImportElectionResultsJob).not_to have_received(:perform_in)
      end
    end

    context 'when discovering elections raises' do
      before { allow(Councils::Qld::Elections).to receive(:local).and_raise('boom') }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform }.to raise_error('boom')
        expect(IngestSourceStatus.find_by(key: described_class.name).last_error).to eq('boom')
      end
    end
  end
end
