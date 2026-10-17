require 'rails_helper'

RSpec.describe Exports::BuildFlattenedExportJob, type: :job do
  before do
    allow(described_class).to receive(:perform_in)
    allow(Exports::FlattenedDataset).to receive(:call)
    allow(Sidekiq::Queue).to receive(:new).and_return(instance_double(Sidekiq::Queue, size: 0))
  end

  describe "the 'people' phase" do
    it 'refreshes stale people and stays in the people phase when more remain' do
      stale_people = create_list(:person, 2, cached_summary_timestamp: nil)
      create(:person, cached_summary_timestamp: 1.day.ago)
      stub_const('Exports::BuildFlattenedExportJob::QUANTITY', 1)

      described_class.new.perform('people')

      expect(stale_people.map(&:reload).count(&:cache_fresh?)).to eq(1)
      expect(described_class).to have_received(:perform_in).with(5.minutes, 'people')
    end

    it 'moves to the groups phase once no people remain stale' do
      create(:person, cached_summary_timestamp: 1.day.ago)

      described_class.new.perform('people')

      expect(described_class).to have_received(:perform_in).with(5.minutes, 'groups')
    end
  end

  describe "the 'groups' phase" do
    it 'refreshes stale groups and stays in the groups phase when more remain' do
      stale_groups = create_list(:group, 2, cached_summary_timestamp: nil)
      stub_const('Exports::BuildFlattenedExportJob::QUANTITY', 1)

      described_class.new.perform('groups')

      expect(stale_groups.map(&:reload).count(&:cache_fresh?)).to eq(1)
      expect(described_class).to have_received(:perform_in).with(5.minutes, 'groups')
    end

    it 'moves to the compose phase once no groups remain stale' do
      create(:group, cached_summary_timestamp: 1.day.ago)

      described_class.new.perform('groups')

      expect(described_class).to have_received(:perform_in).with(5.minutes, 'compose')
    end
  end

  describe "the 'compose' phase" do
    it 'builds and uploads the flattened dataset without rescheduling' do
      described_class.new.perform('compose')

      expect(Exports::FlattenedDataset).to have_received(:call)
      expect(described_class).not_to have_received(:perform_in)
    end
  end
end
