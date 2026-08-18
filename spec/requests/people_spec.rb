require 'rails_helper'

RSpec.describe 'People index pagination' do
  describe 'GET /people' do
    before do
      30.times { |n| create(:person, name: format('Person %02d', n)) }
    end

    it 'shows the first page of results at the default page size' do
      get '/people'

      if response.status == 500
        warn "===CI DEBUG BODY START==="
        warn response.body.gsub(/<[^>]+>/, ' ').squeeze(' ')[0..4000]
        warn "===CI DEBUG BODY END==="
      end

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Person \d\d/).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get '/people'
      page_one_names = response.body.scan(/Person \d\d/).uniq

      get '/people', params: { page: 2 }
      page_two_names = response.body.scan(/Person \d\d/).uniq

      expect(page_two_names.size).to eq(5)
      expect(page_one_names & page_two_names).to be_empty
      expect((page_one_names + page_two_names).uniq.size).to eq(30)
    end
  end
end
