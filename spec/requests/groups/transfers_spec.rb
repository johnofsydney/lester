require 'rails_helper'

RSpec.describe 'Group transfers list pagination' do
  describe 'GET /groups/:id' do
    let(:group) { create(:group) }

    before do
      transfers = Array.new(30) do |n|
        {
          'id' => n + 1,
          'amount' => 100 - n,
          'effective_date' => "2024-01-#{format('%02d', (n % 28) + 1)}",
          'giver_type' => 'Group',
          'giver_id' => group.id,
          'giver_name' => group.name,
          'taker_type' => 'Person',
          'taker_id' => n + 1,
          'taker_name' => format('Group Transfer Taker %02d', n),
          'depth' => 0,
          'direction' => 'outgoing'
        }
      end

      group.cached_summary = { 'direct_connections' => [], 'consolidated_transfers' => transfers }
      group.cached_summary_timestamp = Time.current
      # avoids GroupsController#show's nodes_count falling through to a live
      # Sidekiq::Queue.new('default').size call (hits Redis, not stubbed by
      # Sidekiq::Testing.fake!) when nodes_count isn't already cached
      group.nodes_count_cached = 0
      group.nodes_count_cached_at = Time.current
      group.save!
    end

    it 'shows the first page of results at the default page size' do
      get "/groups/#{group.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Group Transfer Taker \d\d/).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get "/groups/#{group.id}"
      page_one_names = response.body.scan(/Group Transfer Taker \d\d/).uniq

      get "/groups/#{group.id}", params: { transfers_page: 2 }
      page_two_names = response.body.scan(/Group Transfer Taker \d\d/).uniq

      expect(page_two_names.size).to eq(5)
      expect(page_one_names & page_two_names).to be_empty
      expect((page_one_names + page_two_names).uniq.size).to eq(30)
    end
  end
end
