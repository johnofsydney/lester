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

    it 'shows a total result count, not just the current page' do
      lobbyist = create(:group, name: 'Lobbyist')
      30.times do |n|
        member = create(:person, name: format('Member %02d', n))
        create(:membership, member: member, group: lobbyist)
      end

      get '/search/advanced', params: { entity_type: 'Person', filters: [{ facet_value_id: lobbyist.id }] }

      expect(response.body).to include('30 people found')
    end

    it 'shows a singular count for a single result' do
      lobbyist = create(:group, name: 'Lobbyist')
      member = create(:person, name: 'Only One')
      create(:membership, member: member, group: lobbyist)

      get '/search/advanced', params: { entity_type: 'Person', filters: [{ facet_value_id: lobbyist.id }] }

      expect(response.body).to include('1 person found')
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

      field_names = response.body.scan(/name="(filters\[\]\[\w+\]\[?\]?)"/).flatten

      expect(field_names).to eq(%w[
                                  filters[][facet_type] filters[][facet_value_id]
                                  filters[][facet_type] filters[][joiner]
                                  filters[][facet_value_id][] filters[][facet_value_id][]
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

    it 'matches People AND Lobbyists AND (Consulting OR Superannuation), via the real form field order' do
      lobbyists = create(:group, name: 'Lobbyists')
      consulting = create(:group, name: 'Consulting')
      superannuation = create(:group, name: 'Superannuation')

      lobbyist_and_consulting = create(:person, name: 'Lobbyist And Consulting')
      create(:membership, member: lobbyist_and_consulting, group: lobbyists)
      create(:membership, member: lobbyist_and_consulting, group: consulting)

      lobbyist_only = create(:person, name: 'Lobbyist Only')
      create(:membership, member: lobbyist_only, group: lobbyists)

      raw_query = 'entity_type=Person' \
                  "&filters[][facet_type]=Group&filters[][facet_value_id]=#{lobbyists.id}" \
                  '&filters[][facet_type]=Group&filters[][joiner]=AND' \
                  "&filters[][facet_value_id][]=#{consulting.id}&filters[][facet_value_id][]=#{superannuation.id}"

      get "/search/advanced?#{raw_query}"

      expect(response.body).to include("/people/#{lobbyist_and_consulting.id}")
      expect(response.body).not_to include("/people/#{lobbyist_only.id}")
    end

    it 'falls back to Person for an invalid entity_type' do
      get '/search/advanced', params: { entity_type: 'DoesNotExist' }

      expect(response).to have_http_status(:ok)
    end

    it 'does not 500 on a malformed filters param (a scalar instead of an array of hashes)' do
      get '/search/advanced?entity_type=Person&filters=not_an_array_of_hashes'

      expect(response).to have_http_status(:ok)
    end

    it 'does not 500 on a filters param that is an array of scalars' do
      get '/search/advanced?entity_type=Person&filters[]=1&filters[]=2'

      expect(response).to have_http_status(:ok)
    end

    it 'shows no message on the very first, un-submitted visit to the page' do
      get '/search/advanced'

      expect(response.body).not_to include('Choose at least one category to search')
    end

    it 'prompts the user when the form is submitted with nothing selected' do
      get '/search/advanced', params: { entity_type: 'Person' }

      expect(response.body).to include('Choose at least one category to search')
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
