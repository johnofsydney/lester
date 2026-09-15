require 'rails_helper'

RSpec.describe 'Trading name navigation' do
  describe 'GET /tradingnames/:id' do
    it 'redirects a group-owned trading name to the canonical group page' do
      group = create(:group, name: 'Acme Holdings')
      trading_name = group.trading_names.create!(name: 'Acme')

      get "/tradingnames/#{trading_name.id}"

      expect(response).to redirect_to(group_path(group))
    end

    it 'redirects a person-owned trading name to the canonical person page' do
      person = create(:person, name: 'Anthony John Abbott')
      trading_name = person.trading_names.create!(name: 'Tony Abbott')

      get "/tradingnames/#{trading_name.id}"

      expect(response).to redirect_to(person_path(person))
    end
  end
end
