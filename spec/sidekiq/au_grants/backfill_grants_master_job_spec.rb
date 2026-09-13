require 'rails_helper'

RSpec.describe AuGrants::BackfillGrantsMasterJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  before do
    allow(AuGrants::IngestGrantsByDateJob).to receive(:perform_async)
    allow(described_class).to receive(:perform_in)
    allow(Sidekiq::Queue).to receive(:new).and_return(instance_double(Sidekiq::Queue, size: 0))
    travel_to Date.new(2026, 2, 3)
  end

  after { travel_back }

  it 'ingests the target date and schedules the next day' do
    described_class.new.perform('2026-01-31')

    expect(AuGrants::IngestGrantsByDateJob).to have_received(:perform_async).with('2026-01-31')
    expect(described_class).to have_received(:perform_in).with(2.minutes, '2026-02-01')
  end

  context 'when the target date is in the future' do
    it 'does nothing' do
      described_class.new.perform('2026-02-04')

      expect(AuGrants::IngestGrantsByDateJob).not_to have_received(:perform_async)
    end
  end

  context 'when the next day would be in the future' do
    it 'ingests the day but does not schedule a next run' do
      described_class.new.perform('2026-02-03')

      expect(AuGrants::IngestGrantsByDateJob).to have_received(:perform_async).with('2026-02-03')
      expect(described_class).not_to have_received(:perform_in)
    end
  end

  context 'when the queue is overloaded' do
    before { allow(Sidekiq::Queue).to receive(:new).and_return(instance_double(Sidekiq::Queue, size: 3_000)) }

    it 'reschedules itself instead of ingesting' do
      described_class.new.perform('2026-01-31')

      expect(AuGrants::IngestGrantsByDateJob).not_to have_received(:perform_async)
      expect(described_class).to have_received(:perform_in).with(5.minutes, '2026-01-31')
    end
  end
end
