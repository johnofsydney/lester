require 'rails_helper'

RSpec.describe 'GET /api/v1/health' do
  it 'returns an ok status as JSON' do
    get '/api/v1/health'

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include('application/json')
    expect(JSON.parse(response.body)).to include('status' => 'ok')
  end
end
