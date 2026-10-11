require 'rails_helper'

RSpec.describe 'Home' do
  describe 'GET /about' do
    it 'renders the major initiatives table' do
      get '/about'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('NSW/VIC/QLD council election coverage')
      expect(response.body).to include('Being verified')
    end

    it 'shows a healthy data source as OK' do
      IngestSourceStatus.record_success('AusTender::IngestContractsDateJob')

      get '/about'

      expect(response.body).to include('Federal Government Contracts since 2018')
      expect(response.body).to include('OK')
    end

    it 'shows a failing data source as Failing' do
      IngestSourceStatus.record_failure('AuLobbyists::IngestLobbyistsJob', StandardError.new('boom'))

      get '/about'

      expect(response.body).to include('Lobbyists and the Clients of Lobbyists')
      expect(response.body).to include('Failing')
    end

    it 'shows a manual data source without a health badge' do
      get '/about'

      expect(response.body).to include('AEC Annual Donor records since 1999')
      expect(response.body).to include('Manual')
    end
  end
end
