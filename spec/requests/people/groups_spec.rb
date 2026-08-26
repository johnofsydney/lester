require 'rails_helper'

RSpec.describe 'Person groups list pagination' do
  describe 'GET /people/:id' do
    let(:person) { create(:person) }

    before do
      groups = Array.new(30) do |n|
        {
          'klass' => 'Group',
          'id' => n + 1,
          'name' => format('Connected Group %02d', n),
          'last_position' => nil
        }
      end

      person.cached_summary = { 'direct_connections' => groups, 'consolidated_transfers' => [] }
      person.cached_summary_timestamp = Time.current
      person.save!
    end

    it 'shows the first page of results at the default page size' do
      get "/people/#{person.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Connected Group \d\d/).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get "/people/#{person.id}"
      page_one_names = response.body.scan(/Connected Group \d\d/).uniq

      get "/people/#{person.id}", params: { groups_page: 2 }
      page_two_names = response.body.scan(/Connected Group \d\d/).uniq

      expect(page_two_names.size).to eq(5)
      expect(page_one_names & page_two_names).to be_empty
      expect((page_one_names + page_two_names).uniq.size).to eq(30)
    end
  end
end
