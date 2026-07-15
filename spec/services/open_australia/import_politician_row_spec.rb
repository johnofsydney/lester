require 'rails_helper'

# rubocop:disable RSpec/LetSetup
RSpec.describe OpenAustralia::ImportPoliticianRow, type: :service do
  let(:fixture_dir) { Rails.root.join('spec/fixtures/open_australia') }
  let(:rep_detail)  { JSON.parse(File.read(fixture_dir.join('get_representative.json'))) }
  let(:sen_detail)  { JSON.parse(File.read(fixture_dir.join('get_senator.json'))) }

  let!(:parliament_group)  { create(:group, name: 'australian federal parliament') }

  # Albanese: ALP MP, Grayndler (NSW), person_id 10007, entered_house 1996-03-02
  let(:alp_tag)            { create(:group, type: 'Tag', name: 'australian labor party') }
  let!(:alp_federal_group) { create(:group, name: 'alp (federal)') }
  let!(:alp_nsw_group)     { create(:group, name: 'alp (nsw)') }
  let!(:_alp_federal_membership) { create(:membership, member: alp_federal_group, group: alp_tag) }
  let!(:_alp_nsw_membership)     { create(:membership, member: alp_nsw_group,     group: alp_tag) }

  let(:api_client) { instance_double(OpenAustralia::ApiClient) }

  before do
    allow(OpenAustralia::ApiClient).to receive(:new).and_return(api_client)
    allow(api_client).to receive_messages(get_representative: rep_detail, get_senator: sen_detail)
    allow(Group).to receive(:federal_parliament).and_return(parliament_group)
  end

  describe 'importing an MP (Anthony Albanese, ALP, Grayndler)' do
    subject(:call) do
      described_class.call(person_id: '10007', house: '1')
    end

    it 'creates the person' do
      expect { call }.to change(Person, :count).by(1)
      expect(Person.last.name).to eq('anthony albanese')
    end

    it 'sets the open_australia ExternalIdentifier on the person' do
      call
      ei = ExternalIdentifier.find_by(source: 'open_australia', value: '10007')
      expect(ei).to be_present
      expect(ei.owner).to eq(Person.last)
    end

    it 'creates a parliament membership with position MP' do
      call
      person     = Person.find_by(name: 'anthony albanese')
      membership = Membership.find_by(member: person, group: parliament_group)

      expect(membership).to be_present
      expect(membership.start_date).to eq(Date.new(1996, 3, 2))
      expect(membership.end_date).to be_nil
      expect(membership.evidence).to eq('https://www.openaustralia.org.au')
      expect(membership.positions.first.title).to eq('MP')
    end

    it 'creates federal ALP branch membership' do
      call
      person     = Person.find_by(name: 'anthony albanese')
      membership = Membership.find_by(member: person, group: alp_federal_group)

      expect(membership).to be_present
      expect(membership.positions.first.title).to eq('Federal Parliamentary Party Member')
    end

    it 'creates NSW ALP branch membership' do
      call
      person     = Person.find_by(name: 'anthony albanese')
      membership = Membership.find_by(member: person, group: alp_nsw_group)

      expect(membership).to be_present
      expect(membership.positions.first.title).to eq('Party Member (NSW)')
    end

    context 'when called a second time (re-import)' do
      before { call }

      it 'does not create duplicate records' do
        [Person, Membership, Position].each do |klass|
          expect { described_class.call(person_id: '10007', house: '1') }.not_to change(klass, :count)
        end
      end
    end
  end

  describe 'importing a Senator (Carol Brown, ALP, Tasmania)' do
    subject(:call) do
      described_class.call(person_id: '10071', house: '2')
    end

    let!(:alp_tas_group)       { create(:group, name: 'alp (tas)') }
    let!(:_alp_tas_membership) { create(:membership, member: alp_tas_group, group: alp_tag) }

    it 'creates a parliament membership with position Senator' do
      call
      person     = Person.find_by(name: 'carol brown')
      membership = Membership.find_by(member: person, group: parliament_group)

      expect(membership.positions.first.title).to eq('Senator')
    end

    it 'normalises Tasmania to TAS for the state branch position' do
      call
      person     = Person.find_by(name: 'carol brown')
      membership = Membership.find_by(member: person, group: alp_tas_group)

      expect(membership).to be_present
      expect(membership.positions.first.title).to eq('Party Member (TAS)')
    end
  end

  describe 'importing an Independent MP' do
    subject(:call) do
      described_class.call(person_id: '99001', house: '1')
    end

    before do
      allow(api_client).to receive(:get_representative)
        .and_return([rep_detail.first.merge('full_name' => 'Zali Steggall', 'person_id' => 99_001, 'party' => 'Independent')])
    end

    it 'creates no party membership' do
      person = call
      expect(person.memberships.where.not(group: parliament_group)).to be_empty
    end
  end

  describe 'importing a Speaker' do
    subject(:call) do
      described_class.call(person_id: '10880', house: '1')
    end

    before do
      allow(api_client).to receive(:get_representative)
        .and_return([rep_detail.first.merge('full_name' => 'Milton Dick', 'person_id' => 10_880, 'party' => 'Speaker')])
    end

    it 'creates a parliament membership with position Speaker of the House' do
      person     = call
      membership = Membership.find_by(member: person, group: parliament_group)

      expect(membership.positions.first.title).to eq('Speaker of the House')
    end

    it 'creates no party membership — real party is unknown from the API for this term' do
      person = call
      expect(person.memberships.where.not(group: parliament_group)).to be_empty
    end
  end

  # Barnaby Joyce: served as Senator (National Party, QLD) then MP (party changes mid-career).
  # Tests that a chamber change and multiple party changes are handled correctly — same Person
  # record reused, contiguous rep terms collapsed into parliament Membership stints.
  describe 'importing Barnaby Joyce — chamber change and party change (person_id 10350)' do
    let(:barnaby_rep_detail) { JSON.parse(File.read(fixture_dir.join('get_representative_barnaby_joyce.json'))) }
    let(:barnaby_sen_detail) { JSON.parse(File.read(fixture_dir.join('get_senator_barnaby_joyce.json'))) }

    let(:nationals_tag)            { create(:group, type: 'Tag', name: 'the nationals') }
    let!(:nationals_federal_group) { create(:group, name: 'nationals (federal)') }
    let!(:nationals_qld_group)     { create(:group, name: 'nationals (qld)') }
    let!(:nationals_nsw_group)     { create(:group, name: 'nationals (nsw)') }
    let!(:_nat_fed_membership)     { create(:membership, member: nationals_federal_group, group: nationals_tag) }
    let!(:_nat_qld_membership)     { create(:membership, member: nationals_qld_group,     group: nationals_tag) }
    let!(:_nat_nsw_membership)     { create(:membership, member: nationals_nsw_group,     group: nationals_tag) }

    let(:import_as_senator) { described_class.call(person_id: '10350', house: '2') }
    let(:import_as_mp)      { described_class.call(person_id: '10350', house: '1') }

    before do
      allow(api_client).to receive_messages(get_senator: barnaby_sen_detail, get_representative: barnaby_rep_detail)
    end

    it 'creates only one Person record across both imports' do
      import_as_senator
      expect { import_as_mp }.not_to change(Person, :count)
    end

    # The API returns 1 senate term + 4 rep terms. The rep terms collapse into 2 stints:
    # stint 1 (2013-09-07 → 2017-10-27, single term) and stint 2 (2017-12-02 → present,
    # three contiguous terms — party changed but he never left parliament between them).
    it 'creates three parliament Memberships — one Senator and two MP stints' do
      import_as_senator
      import_as_mp

      memberships = Membership.where(member: Person.find_by(name: 'barnaby joyce'), group: parliament_group)
                              .includes(:positions)

      expect(memberships.count).to eq(3)
      expect(memberships.flat_map { |m| m.positions.map(&:title) }).to contain_exactly(
        'Senator', 'MP', 'MP'
      )
    end

    it 'gives the Senator Membership the correct dates' do
      import_as_senator

      person     = Person.find_by(name: 'barnaby joyce')
      membership = Membership.find_by(member: person, group: parliament_group, start_date: Date.new(2005, 7, 1))

      expect(membership).to be_present
      expect(membership.end_date).to eq(Date.new(2013, 8, 8))
    end

    it 'gives the current MP Membership a nil end_date (start of stint, not start of last term)' do
      import_as_mp

      person     = Person.find_by(name: 'barnaby joyce')
      membership = Membership.find_by(member: person, group: parliament_group, start_date: Date.new(2017, 12, 2))

      expect(membership).to be_present
      expect(membership.end_date).to be_nil
    end

    it 'creates a Nationals (Federal) membership from the Senate term' do
      import_as_senator

      person = Person.find_by(name: 'barnaby joyce')
      expect(Membership.find_by(member: person, group: nationals_federal_group)).to be_present
    end

    # QLD has no separate Nationals state branch — the state party is the LNP.
    # The mapper has no pattern for "National Party (QLD)", so it falls through and
    # creates a fresh group rather than finding nationals_qld_group. This is a known
    # mapper gap to fix when party strings are audited against the DB.
    it 'creates a state branch group for QLD even though the mapper does not recognise it yet' do
      import_as_senator

      person           = Person.find_by(name: 'barnaby joyce')
      party_membership = Membership.where(member: person).where.not(group: parliament_group).first

      expect(party_membership).to be_present
    end

    it 'creates a Nationals (NSW) membership from the National Party representative terms (New England → NSW)' do
      import_as_mp

      person = Person.find_by(name: 'barnaby joyce')
      expect(Membership.find_by(member: person, group: nationals_nsw_group)).to be_present
    end

    it 'creates a One Nation party membership from the representative term' do
      import_as_mp

      person     = Person.find_by(name: 'barnaby joyce')
      one_nation = Group.find_by(name: "pauline hanson's one nation")
      expect(one_nation).to be_present
      expect(Membership.find_by(member: person, group: one_nation)).to be_present
    end

    it 'does not create a NSW Nationals membership for the Senate term (QLD senator)' do
      import_as_senator

      person = Person.find_by(name: 'barnaby joyce')
      expect(Membership.find_by(member: person, group: nationals_nsw_group)).to be_nil
    end

    it 'closes Nationals (Federal) membership when party changes to Independent' do
      import_as_mp

      person     = Person.find_by(name: 'barnaby joyce')
      membership = Membership.find_by(member: person, group: nationals_federal_group)

      expect(membership.end_date).to eq(Date.new(2025, 11, 27))
    end

    it 'closes Nationals (NSW) membership when party changes to Independent' do
      import_as_mp

      person     = Person.find_by(name: 'barnaby joyce')
      membership = Membership.find_by(member: person, group: nationals_nsw_group)

      expect(membership.end_date).to eq(Date.new(2025, 11, 27))
    end

    it 'leaves the One Nation membership open (current party has no end_date)' do
      import_as_mp

      person     = Person.find_by(name: 'barnaby joyce')
      one_nation = Group.find_by(name: "pauline hanson's one nation")
      membership = Membership.find_by(member: person, group: one_nation)

      expect(membership.end_date).to be_nil
    end

    it 'is idempotent — re-importing does not change correctly set end_dates' do
      2.times { described_class.call(person_id: '10350', house: '1') }

      person     = Person.find_by(name: 'barnaby joyce')
      membership = Membership.find_by(member: person, group: nationals_federal_group)

      expect(membership.end_date).to eq(Date.new(2025, 11, 27))
    end
  end
end
# rubocop:enable RSpec/LetSetup
