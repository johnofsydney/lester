require 'rails_helper'

RSpec.describe 'Person transfers list pagination' do
  describe 'GET /people/:id' do
    let(:person) { create(:person) }

    before do
      transfers = Array.new(30) do |n|
        {
          'id' => n + 1,
          'amount' => 100 - n,
          'effective_date' => "2024-01-#{format('%02d', (n % 28) + 1)}",
          'giver_type' => 'Person',
          'giver_id' => 1,
          'giver_name' => 'some giver',
          'taker_type' => 'Group',
          'taker_id' => n + 1,
          'taker_name' => format('Transfer Taker %02d', n),
          'depth' => 0,
          'direction' => 'outgoing'
        }
      end

      person.cached_summary = { 'direct_connections' => [], 'consolidated_transfers' => transfers }
      person.cached_summary_timestamp = Time.current
      person.save!
    end

    it 'shows the first page of results at the default page size' do
      get "/people/#{person.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Transfer Taker \d\d/).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get "/people/#{person.id}"
      page_one_names = response.body.scan(/Transfer Taker \d\d/).uniq

      get "/people/#{person.id}", params: { transfers_page: 2 }
      page_two_names = response.body.scan(/Transfer Taker \d\d/).uniq

      expect(page_two_names.size).to eq(5)
      expect(page_one_names & page_two_names).to be_empty
      expect((page_one_names + page_two_names).uniq.size).to eq(30)
    end
  end
end
