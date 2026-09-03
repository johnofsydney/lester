require 'rails_helper'

RSpec.describe 'Advanced search' do
  describe 'GET /search (homepage)' do
    it 'does not link to the advanced search page yet' do
      get '/search'

      expect(response.body).not_to include('/search/advanced')
    end
  end

  describe 'GET /search/advanced' do
    it 'shows no results before any filter is chosen' do
      create(:person, name: 'Anthony Albanese')

      get '/search/advanced'

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Anthony Albanese')
    end

    it 'shows people matching the chosen group filter' do
      lobbyist = create(:group, name: 'Lobbyist')
      member = create(:person, name: 'Anthony Albanese')
      create(:membership, member: member, group: lobbyist)

      get '/search/advanced', params: { entity_type: 'Person', filters: [{ facet_value_id: lobbyist.id }] }

      expect(response.body).to include('Anthony Albanese')
    end

    it 'shows a no-results message when the filter matches nobody' do
      lobbyist = create(:group, name: 'Lobbyist')

      get '/search/advanced', params: { entity_type: 'Person', filters: [{ facet_value_id: lobbyist.id }] }

      expect(response.body).to include('No results found')
    end

    it 'falls back to Person for an invalid entity_type' do
      get '/search/advanced', params: { entity_type: 'DoesNotExist' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /search/advanced/groups' do
    it 'returns groups matching the term' do
      create(:group, name: 'Australian Labor Party')
      create(:group, name: 'Liberal Party')

      get '/search/advanced/groups', params: { q: 'labor' }

      json = response.parsed_body
      expect(json.map { |row| row['name'] }).to include('Australian Labor Party')
      expect(json.map { |row| row['name'] }).not_to include('Liberal Party')
    end

    it 'returns an empty array for a term shorter than the minimum length' do
      create(:group, name: 'Australian Labor Party')

      get '/search/advanced/groups', params: { q: 'a' }

      expect(response.parsed_body).to eq([])
    end

    it 'returns an empty array when no term is given' do
      get '/search/advanced/groups'

      expect(response.parsed_body).to eq([])
    end

    it 'tolerates a typo in one word of a multi-word group name' do
      create(:group, name: 'Australian Labor Party')

      get '/search/advanced/groups', params: { q: 'labour' }

      expect(response.parsed_body.map { |row| row['name'] }).to include('Australian Labor Party')
    end

    it 'caps results at MAX_RESULTS' do
      25.times { |n| create(:group, name: format('Searchable Group %02d', n)) }

      get '/search/advanced/groups', params: { q: 'Searchable Group' }

      expect(response.parsed_body.size).to eq(AdvancedSearchController::MAX_RESULTS)
    end
  end
end
