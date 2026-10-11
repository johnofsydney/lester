require 'rails_helper'

RSpec.describe SidekiqUtils, type: :service do
  # Sidekiq::Queue/ScheduledSet/RetrySet always need a live Redis connection (not made
  # safe by Sidekiq::Testing.fake!, and not available in CI) -- stub them the same way
  # rails_helper already requires for Sidekiq::Queue.
  let(:scheduled_job_in_default) { instance_double(Sidekiq::SortedEntry, queue: 'default', klass: 'SomeJob') }
  let(:scheduled_job_in_low) { instance_double(Sidekiq::SortedEntry, queue: 'low', klass: 'OtherJob') }
  let(:retry_job_in_default) { instance_double(Sidekiq::SortedEntry, queue: 'default') }
  let(:retry_job_in_low) { instance_double(Sidekiq::SortedEntry, queue: 'low') }

  describe '.queue_size' do
    it 'returns the size of the given queue' do
      allow(Sidekiq::Queue).to receive(:new).with('default').and_return(instance_double(Sidekiq::Queue, size: 3))

      expect(described_class.queue_size('default')).to eq(3)
    end
  end

  describe '.scheduled_size' do
    it 'counts only the scheduled jobs in the given queue (happy path)' do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([scheduled_job_in_default, scheduled_job_in_low])

      expect(described_class.scheduled_size('default')).to eq(1)
    end

    it 'returns 0 when nothing is scheduled' do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([])

      expect(described_class.scheduled_size('default')).to eq(0)
    end
  end

  describe '.retry_size' do
    it 'counts only the jobs awaiting retry in the given queue (happy path)' do
      allow(Sidekiq::RetrySet).to receive(:new).and_return([retry_job_in_default, retry_job_in_low])

      expect(described_class.retry_size('default')).to eq(1)
    end
  end

  describe '.already_scheduled?' do
    it 'is true when a scheduled job of that class exists' do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([scheduled_job_in_default])

      expect(described_class.already_scheduled?('SomeJob')).to be(true)
    end

    it 'is false when no scheduled job of that class exists' do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([scheduled_job_in_default])

      expect(described_class.already_scheduled?('NoSuchJob')).to be(false)
    end
  end

  describe '.clear_scheduled_jobs' do
    it 'clears the scheduled set' do
      scheduled_set = instance_double(Sidekiq::ScheduledSet, clear: true)
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_set)

      described_class.clear_scheduled_jobs

      expect(scheduled_set).to have_received(:clear)
    end
  end

  describe 'redis key helpers' do
    let(:redis) { instance_double(Redis) }

    before do
      allow(Sidekiq).to receive(:redis).and_yield(redis)
    end

    it '.set_redis_key sets the key' do
      allow(redis).to receive(:set)

      described_class.set_redis_key('my_key', 'my_value')

      expect(redis).to have_received(:set).with('my_key', 'my_value')
    end

    it '.get_redis_key reads the key' do
      allow(redis).to receive(:get).with('my_key').and_return('my_value')

      expect(described_class.get_redis_key('my_key')).to eq('my_value')
    end

    it '.delete_redis_key deletes the key' do
      allow(redis).to receive(:del)

      described_class.delete_redis_key('my_key')

      expect(redis).to have_received(:del).with('my_key')
    end
  end
end
