require 'rails_helper'
require 'spec_helper'

RSpec.describe FileIngestor, type: :service do
  describe '.general_upload' do
    let(:csv_data) do
      <<~CSV
        group,person,title,evidence,start_date,end_date
        Soccer Team,John Doe,Manager,Some evidence,2023-01-01,2023-12-31
        Soccer Team,jane smith,Goalkeeper,Some evidence,2023-01-01,2023-12-31
        Rugy Team,John Doe,Manager,Some evidence,2024-01-01
        Rugy Team,jane smith,winger,Some evidence,,2022-12-31
        GlObeX COrPorAtIon,John Doe
        globex corporation,jane smith,ceo
      CSV
    end

    shared_examples 'processes the CSV and creates groups, people, memberships and positions' do
      it 'processes the CSV and creates groups, people, memberships and positions', :aggregate_failures do
        upload

        # all of the people and groups should be created
        john = Person.find_by!(name: 'John Doe')
        jane = Person.find_by!(name: 'Jane Smith')
        soccer_team = Group.find_by!(name: 'Soccer Team')
        rugy_team = Group.find_by!(name: 'Rugy Team')
        globex = Group.find_by!(name: 'Globex Corporation')

        # memberships should be created, with the correct start and end dates and evidence if present
        # binding.pry
        soccer_john = Membership.find_by!(member: john, group: soccer_team)
        soccer_jane = Membership.find_by!(member: jane, group: soccer_team)
        expect(soccer_john.evidence).to eq('Some evidence')
        expect(soccer_jane.evidence).to eq('Some evidence')

        rugby_john = Membership.find_by!(member: john, group: rugy_team)
        rugby_jane = Membership.find_by!(member: jane, group: rugy_team)
        expect(rugby_john.evidence).to eq('Some evidence')
        expect(rugby_jane.evidence).to eq('Some evidence')

        globex_john = Membership.find_by!(member: john, group: globex)
        globex_jane = Membership.find_by!(member: jane, group: globex)

        # positions should be created if the title is present
        soccer_john_position = soccer_john.positions.find_by!(title: 'Manager')
        soccer_jane_position = soccer_jane.positions.find_by!(title: 'Goalkeeper')
        expect(soccer_john_position.evidence).to eq('Some evidence')
        expect(soccer_john_position.start_date).to eq(Date.parse('2023-01-01'))
        expect(soccer_john_position.end_date).to eq(Date.parse('2023-12-31'))
        expect(soccer_jane_position.evidence).to eq('Some evidence')
        expect(soccer_jane_position.start_date).to eq(Date.parse('2023-01-01'))
        expect(soccer_jane_position.end_date).to eq(Date.parse('2023-12-31'))

        rugby_john_position = rugby_john.positions.find_by!(title: 'Manager')
        rugby_jane_position = rugby_jane.positions.find_by!(title: 'Winger')
        expect(rugby_john_position.evidence).to eq('Some evidence')
        expect(rugby_john_position.start_date).to eq(Date.parse('2024-01-01'))
        expect(rugby_john_position.end_date).to be_nil
        expect(rugby_jane_position.evidence).to eq('Some evidence')
        expect(rugby_jane_position.start_date).to be_nil
        expect(rugby_jane_position.end_date).to eq(Date.parse('2022-12-31'))

        globex_john_positions = globex_john.positions
        expect(globex_john_positions).to be_empty

        globex_jane_position = globex_jane.positions.find_by!(title: 'CEO')
        expect(globex_jane_position.evidence).to be_nil
        expect(globex_jane_position.start_date).to be_nil
        expect(globex_jane_position.end_date).to be_nil
      end
    end

    context 'when csv text is passed' do
      subject(:upload) { described_class.general_upload(csv:) }

      let(:csv) { CSV.parse(csv_data, headers: true) }

      it_behaves_like 'processes the CSV and creates groups, people, memberships and positions'
    end

    context 'when csv file is passed' do
      subject(:upload) { described_class.general_upload(file:) }

      let(:file) { Rails.root.join('spec/fixtures/general_upload.csv') }

      it_behaves_like 'processes the CSV and creates groups, people, memberships and positions'
    end
  end
end
