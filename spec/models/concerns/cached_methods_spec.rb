require 'rails_helper'

RSpec.describe CachedMethods do
  [:person, :group].each do |factory|
    context "for a #{factory}" do
      let(:record) { create(factory) }

      it 'does not bump updated_at when only ignored attributes change' do
        record.update!(updated_at: 1.week.ago)
        original_updated_at = record.updated_at

        record.update!(views: record.views + 1, nodes_count_cached: 5, nodes_count_cached_at: Time.current)

        expect(record.reload.updated_at).to be_within(1.second).of(original_updated_at)
      end

      it 'bumps updated_at when cached_data changes' do
        record.update!(updated_at: 1.week.ago)

        record.update!(cached_data: { summary: 'x' })

        expect(record.reload.updated_at).to be_within(1.second).of(Time.current)
      end

      it 'bumps updated_at when a non-ignored attribute changes alongside ignored ones' do
        record.update!(updated_at: 1.week.ago)

        record.update!(name: 'a brand new name', views: record.views + 1)

        expect(record.reload.updated_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
