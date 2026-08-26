require 'rails_helper'

RSpec.describe 'Search pagination' do
  describe 'GET /search' do
    before do
      30.times { |n| create(:person, name: format('Searchable Person %02d', n)) }
    end

    it 'shows the first page of results at the default page size' do
      get '/search', params: { query: 'Searchable Person' }

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/searchable person \d\d/i).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get '/search', params: { query: 'Searchable Person' }
      page_one_names = response.body.scan(/searchable person \d\d/i).uniq

      get '/search', params: { query: 'Searchable Person', page: 2 }
      page_two_names = response.body.scan(/searchable person \d\d/i).uniq

      expect(page_two_names.size).to eq(5)
      expect(page_one_names & page_two_names).to be_empty
      expect((page_one_names + page_two_names).uniq.size).to eq(30)
    end

    it 'preserves the search query in the page-nav links' do
      get '/search', params: { query: 'Searchable Person' }

      expect(response.body).to include('/search?page=2&query=Searchable+Person')
    end
  end
end
