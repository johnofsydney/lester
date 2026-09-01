require 'rails_helper'

RSpec.describe 'Search matching quality' do
  describe 'GET /search' do
    it 'finds a result despite a typo, via trigram matching' do
      create(:person, name: 'Bronwyn Halfpenny')

      get '/search', params: { query: 'Bronwyn Halfpeny' }

      expect(response.body).to include('Bronwyn Halfpenny')
    end

    it 'finds a result despite an accent mismatch, via unaccent' do
      create(:person, name: 'José Ramos')

      get '/search', params: { query: 'Jose Ramos' }

      expect(response.body).to include('José Ramos')
    end
  end
end
