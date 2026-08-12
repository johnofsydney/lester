require 'rails_helper'

RSpec.describe AuLobbyists::ImportLobbyistsPeopleRowJob do
  let!(:lobbyists_tag) { Group.create!(name: 'Lobbyists') }

  before { allow(Group).to receive(:lobbyists_tag).and_return(lobbyists_tag) }

  def perform(person_name: 'Jane Doe', title: 'Consultant', start_date: '2024-01-01',
              lobbyist_name: 'Acme Lobbying', lobbyist_abn: '12345678901')
    described_class.new.perform(person_name, title, start_date, lobbyist_name, lobbyist_abn)
  end

  it 'creates a person, employer membership, tag membership, and position' do
    expect { perform }.to change(Person, :count).by(1).and change(Membership, :count).by(2)

    person = Person.find_by(name: 'jane doe')
    lobbyist = Group.find_by(name: 'Acme Lobbying')

    expect(Membership.exists?(member: person, group: lobbyist)).to be(true)
    expect(Membership.exists?(member: person, group: lobbyists_tag)).to be(true)
    expect(Position.find_by(membership: Membership.find_by(member: person, group: lobbyist)).title).to eq('Consultant')
  end

  context 'when run twice with the same row' do
    it 'is idempotent and does not create duplicate people, memberships, or positions' do
      perform

      expect { perform }.not_to(change do
        [Person.count, Membership.count, Position.count]
      end)
    end
  end

  context 'when the employer membership already exists without a start date or evidence' do
    it 'backfills the start date and evidence rather than creating a duplicate membership' do
      person = FactoryBot.create(:person, name: 'jane doe')
      lobbyist = FactoryBot.create(:group, name: 'acme lobbying')
      membership = Membership.create!(member: person, group: lobbyist)

      expect { perform }.to change(Membership, :count).by(1) # the lobbyists-tag membership is still new

      expect(membership.reload.start_date).to eq(Date.parse('2024-01-01'))
      expect(membership.evidence).to eq('https://lobbyists.ag.gov.au/register')
    end
  end
end
