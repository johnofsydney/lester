require 'rails_helper'

RSpec.describe 'Advanced search' do
  describe 'GET /search/advanced' do
    it 'renders the empty filter form without running a query' do
      get '/search/advanced'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Advanced search')
    end

    it 'returns people matching a single category filter' do
      lobbyists = create(:tag, name: 'Lobbyists')
      alice = create(:person, name: 'Alice Lobbyist')
      create(:person, name: 'Bob Nobody')
      create(:membership, member: alice, group: lobbyists)

      get '/search/advanced', params: { entity_type: 'Person', filters: [{ facet_type: 'Category', facet_value_id: lobbyists.id }] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Alice Lobbyist')
      expect(response.body).not_to include('Bob Nobody')
    end

    it 'ignores filter rows without a facet value and shows nothing is being filtered' do
      alice = create(:person, name: 'Alice Standalone')

      get '/search/advanced', params: { entity_type: 'Person', filters: [{ facet_type: 'Category', facet_value_id: '' }] }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Alice Standalone')
    end
  end

  describe 'GET /search/advanced/groups' do
    it 'returns groups matching the search term as JSON' do
      create(:group, name: 'Greenpeace')
      create(:group, name: 'Totally Unrelated')

      get '/search/advanced/groups', params: { term: 'Greenpeace' }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |row| row['name'] }).to include('Greenpeace')
      expect(body.map { |row| row['name'] }).not_to include('Totally Unrelated')
    end

    it 'returns an empty array for a very short term' do
      get '/search/advanced/groups', params: { term: 'a' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
