require 'rails_helper'

RSpec.describe 'Group affiliated groups tab pagination' do
  describe 'GET /groups/affiliated_groups/:group_id' do
    let(:group) { create(:group) }

    before do
      affiliated_groups = Array.new(30) do |n|
        {
          'klass' => 'Group',
          'id' => n + 1,
          'name' => format('Affiliated Group %02d', n),
          'is_tag' => false,
          'last_position' => nil
        }
      end

      tags = Array.new(30) do |n|
        {
          'klass' => 'Tag',
          'id' => n + 1000,
          'name' => format('Tag %02d', n),
          'last_position' => nil
        }
      end

      group.cached_summary = { 'direct_connections' => affiliated_groups + tags }
      group.save!
    end

    it 'shows the first page of each list at the default page size, independently' do
      get "/groups/affiliated_groups/#{group.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Affiliated Group \d\d/).uniq.size).to eq(25)
      expect(response.body.scan(/TAG \d\d/).uniq.size).to eq(25)
    end

    it 'paginates affiliated groups independently of tags via groups_page' do
      get "/groups/affiliated_groups/#{group.id}"
      page_one_groups = response.body.scan(/Affiliated Group \d\d/).uniq

      get "/groups/affiliated_groups/#{group.id}", params: { groups_page: 2 }
      page_two_groups = response.body.scan(/Affiliated Group \d\d/).uniq
      tags_still_page_one = response.body.scan(/TAG \d\d/).uniq

      expect(page_two_groups.size).to eq(5)
      expect(page_one_groups & page_two_groups).to be_empty
      expect(tags_still_page_one.size).to eq(25)
    end

    it 'paginates tags independently of affiliated groups via tags_page' do
      get "/groups/affiliated_groups/#{group.id}"
      page_one_tags = response.body.scan(/TAG \d\d/).uniq

      get "/groups/affiliated_groups/#{group.id}", params: { tags_page: 2 }
      page_two_tags = response.body.scan(/TAG \d\d/).uniq
      groups_still_page_one = response.body.scan(/Affiliated Group \d\d/).uniq

      expect(page_two_tags.size).to eq(5)
      expect(page_one_tags & page_two_tags).to be_empty
      expect(groups_still_page_one.size).to eq(25)
    end
  end
end
