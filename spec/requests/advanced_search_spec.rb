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

    it 'pre-selects the chosen entity type, categories, and joiner in the form' do
      lobbyist_tag = create(:group, name: 'Lobbyist Tag', type: 'Tag')
      alp_tag = create(:group, name: 'Australian Labor Party', type: 'Tag')

      get '/search/advanced', params: {
        entity_type: 'Person',
        filters: [
          { facet_type: 'Category', facet_value_id: lobbyist_tag.id },
          { facet_type: 'Category', joiner: 'OR', facet_value_id: alp_tag.id }
        ]
      }

      expect(response.body).to include(%(<option selected="selected" value="Person">))
      expect(response.body).to include(%(<option selected="selected" value="#{lobbyist_tag.id}">))
      expect(response.body).to include(%(<option selected="selected" value="OR">))
      expect(response.body).to include(%(<option selected="selected" value="#{alp_tag.id}">))
    end

    it 'renders row 2 fields in an order Rack groups into a single filter hash' do
      # A hash-of-array field (filters[][...]) is only grouped correctly by Rack if the
      # repeated subkey (facet_type) appears before any other subkey in that row - so
      # facet_type must render first in row 2, not joiner.
      get '/search/advanced'

      field_names = response.body.scan(/name="(filters\[\]\[\w+\])"/).flatten

      expect(field_names).to eq(%w[
                                  filters[][facet_type] filters[][facet_value_id]
                                  filters[][facet_type] filters[][joiner] filters[][facet_value_id]
                                ])
    end

    it 'honors an OR joiner submitted the way the rendered form actually orders its fields' do
      # Rack groups a repeated array-of-hashes key (filters[][...]) into a new hash as
      # soon as it sees a repeated subkey - this exercises that exact field order rather
      # than a Ruby params hash, which sidesteps the ordering the real form emits.
      lobbyist = create(:group, name: 'Lobbyist')
      alp = create(:group, name: 'Australian Labor Party')

      only_lobbyist = create(:person, name: 'Only Lobbyist')
      create(:membership, member: only_lobbyist, group: lobbyist)

      raw_query = 'entity_type=Person' \
                  "&filters[][facet_type]=Group&filters[][facet_value_id]=#{lobbyist.id}" \
                  "&filters[][facet_type]=Group&filters[][joiner]=OR&filters[][facet_value_id]=#{alp.id}"

      get "/search/advanced?#{raw_query}"

      expect(response.body).to include("/people/#{only_lobbyist.id}")
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
