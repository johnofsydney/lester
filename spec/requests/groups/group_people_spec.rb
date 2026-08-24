require 'rails_helper'

RSpec.describe 'Group people tab pagination' do
  describe 'GET /groups/group_people/:group_id' do
    let(:group) { create(:group) }

    before do
      people = Array.new(30) do |n|
        {
          'klass' => 'Person',
          'id' => n + 1,
          'name' => format('Group Person %02d', n),
          'last_position' => nil
        }
      end

      group.cached_summary = { 'direct_connections' => people }
      group.save!
    end

    it 'shows the first page of results at the default page size' do
      get "/groups/group_people/#{group.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Group Person \d\d/).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get "/groups/group_people/#{group.id}"
      page_one_names = response.body.scan(/Group Person \d\d/).uniq

      get "/groups/group_people/#{group.id}", params: { page: 2 }
      page_two_names = response.body.scan(/Group Person \d\d/).uniq

      expect(page_two_names.size).to eq(5)
      expect(page_one_names & page_two_names).to be_empty
      expect((page_one_names + page_two_names).uniq.size).to eq(30)
    end
  end

  describe 'ordering' do
    let(:group) { create(:group) }

    before do
      group.cached_summary = {
        'direct_connections' => [
          { 'klass' => 'Person', 'id' => 1, 'name' => 'Aaron Former Member', 'current' => false },
          { 'klass' => 'Person', 'id' => 2, 'name' => 'Zoe Present Member', 'current' => true }
        ]
      }
      group.save!
    end

    it 'lists current members before ex-members, regardless of name' do
      get "/groups/group_people/#{group.id}"

      body = response.body
      expect(body.index('Zoe Present Member')).to be < body.index('Aaron Former Member')
    end
  end
end
