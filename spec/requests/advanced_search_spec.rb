require 'rails_helper'

RSpec.describe 'Advanced search group autocomplete' do
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
