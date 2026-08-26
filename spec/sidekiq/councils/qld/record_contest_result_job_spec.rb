require 'rails_helper'

RSpec.describe Councils::Qld::RecordContestResultJob, type: :job do
  describe '#perform' do
    let(:stub) { '2024QLGE' }
    let(:source_url) { format(Councils::Qld::ImportElectionResultsJob::DECLARED_CANDIDATES_URL, stub:) }

    before do
      FactoryBot.create(:group, name: Group::NAMES.liberals.qld, type: 'Tag')
      # Group.government_department_tag is hardcoded to a production-only ID (app/models/group.rb),
      # invoked internally by Tag::AddGroupToTag -- stub it so it doesn't blow up against the test DB.
      allow(Group).to receive(:government_department_tag).and_return(FactoryBot.create(:group, name: 'government department tag', type: 'Tag'))
    end

    context 'for a single-winner mayoral contest' do
      let(:candidates) { [{ 'name' => 'SCHRINNER, Adrian Jurgen', 'party' => 'Liberal National Party of Queensland' }] }

      it 'creates the council as a Group tagged into Australian Local Councils, with a "Council" suffix' do
        described_class.new.perform(stub, 'Brisbane City', 'Brisbane City', 'mayor', candidates, '2024-04-02', source_url)

        council = Group.find_by(name: 'Brisbane City Council')
        tag = Group.find_by(name: Councils::Qld::RecordContestResultJob::LOCAL_COUNCILS_TAG_NAME)
        expect(council).to be_present
        expect(Membership.exists?(group: tag, member: council)).to be(true)
      end

      it 'records the candidate as a Person with an undated Mayor Position' do
        described_class.new.perform(stub, 'Brisbane City', 'Brisbane City', 'mayor', candidates, '2024-04-02', source_url)

        council = Group.find_by(name: 'Brisbane City Council')
        person = Person.find_by(name: 'adrian jurgen schrinner')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.end_date).to be_nil
        expect(membership.evidence).to include('Electoral Commission of Queensland')
        expect(membership.positions.pluck(:title)).to eq(['Mayor'])
      end

      it 'links the candidate to their party tag via the free-text label' do
        described_class.new.perform(stub, 'Brisbane City', 'Brisbane City', 'mayor', candidates, '2024-04-02', source_url)

        person = Person.find_by(name: 'adrian jurgen schrinner')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.liberals.qld), member: person)).to be(true)
      end

      it 'appends a raw observation to the Person\'s council_election_data, keyed by the resolved council name' do
        described_class.new.perform(stub, 'Brisbane City', 'Brisbane City', 'mayor', candidates, '2024-04-02', source_url)

        person = Person.find_by(name: 'adrian jurgen schrinner')
        observation = person.council_election_data.first

        expect(observation['state']).to eq('qld')
        expect(observation['council_name']).to eq('brisbane city council')
        expect(observation['council_slug']).to eq('Brisbane City')
        expect(observation['cycle']).to eq('2024QLGE')
        expect(observation['declared_date']).to eq('2024-04-02')
        expect(observation['party']).to eq('Liberal National Party of Queensland')
      end
    end

    context 'for a multi-winner councillor contest with no party shown' do
      let(:candidates) do
        [
          { 'name' => 'MARROTT, Jayden Isaac', 'party' => nil },
          { 'name' => 'YUNKAPORTA, Leona Nanette', 'party' => nil }
        ]
      end

      it 'records each candidate as a Person with an undated Councillor Position, and no party membership' do
        described_class.new.perform(stub, 'Aurukun Shire', 'Aurukun Shire Division 1', 'councillor', candidates, '2024-03-21', source_url)

        council = Group.find_by(name: 'Aurukun Shire Council')
        marrott = Person.find_by(name: 'jayden isaac marrott')
        yunkaporta = Person.find_by(name: 'leona nanette yunkaporta')

        expect(Membership.find_by(group: council, member: marrott).positions.pluck(:title)).to eq(['Councillor'])
        expect(Membership.find_by(group: council, member: yunkaporta).positions.pluck(:title)).to eq(['Councillor'])
        expect(Membership.where(member: marrott).where.not(group: council).count).to eq(0)
      end
    end

    context 'when a candidate was already an open member of the council (re-elected)' do
      let(:candidates) { [{ 'name' => 'Barbara Sue Bandicootcha', 'party' => nil }] }
      let!(:council) { FactoryBot.create(:group, name: 'Aurukun Shire Council') }
      let!(:returning_person) { FactoryBot.create(:person, name: 'Barbara Sue Bandicootcha') }
      let!(:returning_membership) { Membership.create!(group: council, member: returning_person, evidence: 'original evidence') }

      it 'reuses the existing open membership rather than creating a new one' do
        expect do
          described_class.new.perform(stub, 'Aurukun Shire', 'Aurukun Shire', 'mayor', candidates, '2024-03-28', source_url)
        end.to change(Membership, :count).by(1) # +1 council->tag membership only; candidate reuses their existing membership

        expect(Membership.where(group: council, member: returning_person).count).to eq(1)
        expect(returning_membership.reload.evidence).to eq('original evidence')
      end
    end
  end
end
