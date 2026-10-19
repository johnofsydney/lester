require 'rails_helper'

RSpec.describe CachedMethods do
  [:person, :group].each do |factory|
    context "for a #{factory}" do
      let(:record) { create(factory) }

      it 'does not bump updated_at when only ignored attributes change' do
        record.update!(updated_at: 1.week.ago)
        original_updated_at = record.updated_at

        record.update!(views: record.views + 1, nodes_count_cached_at: Time.current)

        expect(record.reload.updated_at).to be_within(1.second).of(original_updated_at)
      end

      it 'bumps updated_at when cached_data changes' do
        record.update!(updated_at: 1.week.ago)

        record.update!(cached_data: { summary: 'x' })

        expect(record.reload.updated_at).to be_within(1.second).of(Time.current)
      end

      it 'bumps updated_at when nodes_count_cached changes' do
        record.update!(updated_at: 1.week.ago)

        record.update!(nodes_count_cached: 5)

        expect(record.reload.updated_at).to be_within(1.second).of(Time.current)
      end

      it 'bumps updated_at when a non-ignored attribute changes alongside ignored ones' do
        record.update!(updated_at: 1.week.ago)

        record.update!(name: 'a brand new name', views: record.views + 1)

        expect(record.reload.updated_at).to be_within(1.second).of(Time.current)
      end

      describe '#refresh_cached_data!' do
        let(:setter) { double('Sidekiq::Job::Setter') } # rubocop:disable RSpec/VerifiedDoubles

        before do
          allow(Cache::RefreshCachedDataJob).to receive(:set).and_return(setter)
          allow(setter).to receive(:perform_async)
        end

        it 'enqueues the job on the low queue by default' do
          record.refresh_cached_data!

          expect(Cache::RefreshCachedDataJob).to have_received(:set).with(queue: :low)
          expect(setter).to have_received(:perform_async).with(record.class.name, record.id)
        end

        it 'enqueues on the given queue when one is passed' do
          record.refresh_cached_data!(queue: :critical)

          expect(Cache::RefreshCachedDataJob).to have_received(:set).with(queue: :critical)
          expect(setter).to have_received(:perform_async).with(record.class.name, record.id)
        end
      end

      describe '.cache_stale' do
        it 'includes records with no cached summary timestamp' do
          expect(record.class.cache_stale).to include(record)
        end

        it 'includes records with a cached summary timestamp older than a week' do
          record.update!(cached_summary_timestamp: 8.days.ago)

          expect(record.class.cache_stale).to include(record)
        end

        it 'excludes records with a fresh cached summary timestamp' do
          record.update!(cached_summary_timestamp: 1.day.ago)

          expect(record.class.cache_stale).not_to include(record)
        end
      end
    end
  end
end
