require 'rails_helper'

RSpec.describe 'Transfers index pagination' do
  describe 'GET /transfers' do
    before do
      30.times do |n|
        giver = create(:person, name: format('Transfer Giver %02d', n))
        taker = create(:group, name: format('Transfer Taker %02d', n))
        Transfer.create!(
          giver: giver,
          taker: taker,
          amount: n + 1,
          transfer_type: 'donations',
          effective_date: Date.current
        )
      end
    end

    it 'shows the first page of results at the default page size' do
      get '/transfers'

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/Transfer Giver \d\d/).uniq.size).to eq(25)
    end

    it 'shows the remaining results on page 2 without repeating or skipping rows' do
      get '/transfers'
      page_one_givers = response.body.scan(/Transfer Giver \d\d/).uniq

      get '/transfers', params: { page: 2 }
      page_two_givers = response.body.scan(/Transfer Giver \d\d/).uniq

      expect(page_two_givers.size).to eq(5)
      expect(page_one_givers & page_two_givers).to be_empty
      expect((page_one_givers + page_two_givers).uniq.size).to eq(30)
    end
  end
end
