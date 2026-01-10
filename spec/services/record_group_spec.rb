require 'rails_helper'
require 'spec_helper'

RSpec.describe RecordGroup, type: :service do

  let(:group_names) { Group::NAMES }

  let(:name_combos) do
    {
      # Coalition
      'Liberal Party of Australia' => group_names.liberals.federal,
      'Liberal Party of Australia (S.A. Division)' => group_names.liberals.sa,
      'Liberal Party of Australia - Tasmanian Division' => group_names.liberals.tas,
      'Liberal Party of Australia, NSW Division' => group_names.liberals.nsw,
      'Liberal National Party of Queensland' => group_names.liberals.qld,
      'LIB-ACT' => group_names.liberals.act,
      'LIB-TAS' => group_names.liberals.tas,
      'LIB-NSW' => group_names.liberals.nsw,
      'LIB-FED' => group_names.liberals.federal,
      'LIB-VIC' => group_names.liberals.vic,
      'LIB-SA' => group_names.liberals.sa,
      'LIB - TAS' => group_names.liberals.tas,
      'LIB - NSW' => group_names.liberals.nsw,
      'LIB - FED' => group_names.liberals.federal,
      'LIB - VIC' => group_names.liberals.vic,
      'LIB - SA' => group_names.liberals.sa,
      'National Party of Australia' => group_names.nationals.federal,
      'Liberal Party of Australia (Victorian Division)' => group_names.liberals.vic,
      'Liberal Party (W.A. Division) Inc' => group_names.liberals.wa,
      'National Party of Australia - N.S.W.' => group_names.nationals.nsw,
      'Liberal Party of Australia - ACT Division' => group_names.liberals.act,
      'Country Liberal Party (NT)' => group_names.liberals.nt,
      'CLP-NT' => group_names.liberals.nt,
      'LIB VIC' => group_names.liberals.vic,
      'LIB-FED Liberal Party of Australia (Menzies Research Centre)' => group_names.liberals.federal,
      'LIB-WA' => group_names.liberals.wa,
      'LNP-QLD' => group_names.liberals.qld,
      'Lib-Fed' => group_names.liberals.federal,
      'Lib-NSW' => group_names.liberals.nsw,
      'Liberal National Party' => group_names.liberals.federal,
      'Liberal National Party (LNP-QLD)' => group_names.liberals.qld,
      'Liberal National Party LNP QLD' => group_names.liberals.qld,
      'Liberal National Party of QLD' => group_names.liberals.qld,
      'Liberal Party (W.A. Division) Inc. (LIB-WA)' => group_names.liberals.wa,
      'Liberal Party NSW Division' => 'Liberals (NSW)',
      'Liberal Party of Australia (LIB-FED)' => group_names.liberals.federal,
      'Liberal Party of Australia (NSW Division)' => group_names.liberals.nsw,
      'Liberal Party of Australia (SA Division)' => group_names.liberals.sa,
      'Liberal Party of Australia (SA Division) (LDP-SA)' => group_names.liberals.sa,
      'Liberal Party of Australia (WA Division)' => group_names.liberals.wa,
      'Liberal Party of Australia (WA) (LIB-WA)' => group_names.liberals.wa,
      'Liberal Party of Australia LIB NSW' => group_names.liberals.nsw,
      'Liberal Party of Australia NSW Division' => group_names.liberals.nsw,
      'The Liberal Party of Australia (LIB-FED)' => group_names.liberals.federal,
      'NAT - NSW' => group_names.nationals.nsw,
      'NAT-FED' => group_names.nationals.federal,
      'NAT-NSW' => group_names.nationals.nsw,
      'National Party of Australia (NAT-FED)' => group_names.nationals.federal,
      'National Party of Australia (WA) Inc' => group_names.nationals.wa,
      'National Party of Australia - Victoria' => group_names.nationals.vic,
      'National Party of Australia NAT NSW' => group_names.nationals.nsw,
      'Country Liberals (Northern Territory)' => group_names.liberals.nt,
      'LIB - WA' => group_names.liberals.wa,
      'LIB FED' => group_names.liberals.federal,
      'LIB NSW' => group_names.liberals.nsw,
      'LIB-FEC' => group_names.liberals.federal,
      'LIB-VIC Kooyong 200 Club' => group_names.liberals.vic,
      'LIB-WA Liberal Party (WA Division Inc)' => group_names.liberals.wa,
      'LNP - QLD' => group_names.liberals.qld,
      'Liberal National Party of Queensland - LNP-QLD' => group_names.liberals.qld,
      'Liberal National Party of Queensland - Maiwar' => group_names.liberals.qld,
      'Liberal Part of Australia SA Division - Colton' => group_names.liberals.sa,
      'Liberal Part of Australia SA Division - Dunstan' => group_names.liberals.sa,
      'Liberal Part of Australia SA Division - Unley' => group_names.liberals.sa,
      'Liberal Part of Australia SA Division- Dunstan' => group_names.liberals.sa,
      'Liberal Party NSW (LIB-NSW)' => group_names.liberals.nsw,
      'Liberal Party VIC Division' => group_names.liberals.vic,
      'Liberal Party of Australia (Federal Secretariat)' => group_names.liberals.federal,
      'Liberal Party of Australia (VIC Division) (paid to Enterprise Victoria)' => group_names.liberals.vic,
      'Liberal Party of Australia - LIB-FED' => group_names.liberals.federal,
      'Liberal Party of Australia - LIB-NSW' => group_names.liberals.nsw,
      'Liberal Party of Australia - LIB-SA' => group_names.liberals.sa,
      'Liberal Party of Australia - LIB-TAS' => group_names.liberals.tas,
      'Liberal Party of Australia - LIB-VIC' => group_names.liberals.vic,
      'Liberal Party of Australia Federal Forum/LIB-NSW' => group_names.liberals.nsw,
      'Liberal Party of Australia LIB-FED' => group_names.liberals.federal,
      'Liberal Party of Australia NSW Division - Bega' => group_names.liberals.nsw,
      'Liberal Party of Australia, NSW Division (LIB-NSW)' => group_names.liberals.nsw,
      'Liberal Party of Australia/LIB-NSW' => group_names.liberals.nsw,
      'NAT-WA National Party of Australia (WA) Inc' => group_names.nationals.wa,
      'National Party of Australia - NAT-FED' => group_names.nationals.federal,
      'National Party of Australia - NAT-NSW' => group_names.nationals.nsw,
      'National Party of Australia - NSW' => group_names.nationals.nsw,
      'National Party of Victoria (NAT-VIC)' => group_names.nationals.vic,
      'The Liberal Party of Australia - Victoria Division' => group_names.liberals.vic,
      'The Nationals NAT-FED' => group_names.nationals.federal,
      # ALP
      'ALP-NSW' => group_names.labor.nsw,
      'WA Labor (ALP-WA)' => group_names.labor.wa,
      'The Australian Labour Party National Secretariat' => group_names.labor.federal,
      'ALP - NSW' => group_names.labor.nsw,
      'ALP National (ALP-FED)' => group_names.labor.federal,
      'ALP-QLD' => group_names.labor.qld,
      'ALP-VIC' => group_names.labor.vic,
      'Australian Labor Party (State of Queensland)' => group_names.labor.qld,
      'Australian Labor Party (Western Australian Branch)' => group_names.labor.wa,
      'Australian Labor Party (N.S.W. Branch)' => group_names.labor.nsw,
      'Australian Labor Party (ALP)' => group_names.labor.federal,
      'Australian Labor Party (Victorian Branch)' => group_names.labor.vic,
      'Australian Labor Party (Northern Territory) Branch' => group_names.labor.nt,
      'ALP-SA' => group_names.labor.sa,
      'ALP-FED' => group_names.labor.federal,
      'Australian Labor Party (South Australian Branch)' => group_names.labor.sa,
      'Australian Labor Party (ACT Branch)' => group_names.labor.act,
      'Australian Labor Party (ALP-FED)' => group_names.labor.federal,
      'Australian Labor Party (Northern Territory Branch)' => group_names.labor.nt,
      'Australian Labor Party (Victoria Branch) (ALP - VIC)' => group_names.labor.vic,
      'Australian Labor Party (Western Australia Branch) (ALP-WA)' => group_names.labor.wa,
      'Australian Labor Party (NSW Branch)'  => group_names.labor.nsw,
      'Australian Labor Party (NSW)'  => group_names.labor.nsw,
      'Australian Labor Party (Queensland)'  => group_names.labor.qld,
      'Australian Labor Party (State of Queensland) / ALP-QLD'  => group_names.labor.qld,
      'Australian Labor Party (Tasmanian Branch)'  => group_names.labor.tas,
      'Australian Labor Party (Western Australia Branch)'  => group_names.labor.wa,
      'Australian Labor Party - ALP-FED'  => group_names.labor.federal,
      'Australian Labor Party - ALP-NSW'  => group_names.labor.nsw,
      'Australian Labor Party - ALP-QLD'  => group_names.labor.qld,
      'Australian Labor Party - ALP-SA'  => group_names.labor.sa,
      'Australian Labor Party - ALP-VIC'  => group_names.labor.vic,
      'Australian Labor Party Victorian Branch'  => group_names.labor.vic,
      'ALP - FED'  => group_names.labor.federal,
      'ALP - SA'  => group_names.labor.sa,
      'ALP - TAS'  => group_names.labor.tas,
      'ALP - VIC'  => group_names.labor.vic,
      'ALP - WA'  => group_names.labor.wa,
      'ALP NSW BRANCH'  => group_names.labor.nsw,
      'ALP NSW Branch'  => group_names.labor.nsw,
      'ALP National Secretaria'  => group_names.labor.federal,
      'ALP National Secretariat'  => group_names.labor.federal,
      'ALP National Secretariat/ALP-FED'  => group_names.labor.federal,
      'ALP New South Wales Branch/ALP-NSW'  => group_names.labor.nsw,
      'ALP QLD'  => group_names.labor.qld,
      'ALP QLD - Mulgrave'  => group_names.labor.qld,
      'ALP QLD - South Brisbane'  => group_names.labor.qld,
      'ALP VIC Branch'  => group_names.labor.vic,
      'ALP-ACT'  => group_names.labor.act,
      'ALP-FED Federal Labor Business Forum'  => group_names.labor.federal,
      'ALP-SA Australian Labor Party (South Australian Branch)'  => group_names.labor.sa,
      'ALP-TAS'  => group_names.labor.tas,
      'ALP-WA'  => group_names.labor.wa,
      'ALP-WA Australian Labor Party (Western Australian Branch)'  => group_names.labor.wa,
      'Country Labor Party'  => group_names.labor.federal,
      'Country Labor Party - CLR-NSW'  => group_names.labor.nsw,
      # Greens
      'Australian Greens' => group_names.greens.federal,
      'The Greens (WA) Inc' => group_names.greens.wa,
      'The Australian Greens - Victoria' => group_names.greens.vic,
      'Queensland Greens' => group_names.greens.qld,
      'The Australian Greens (GRN-VIC) (Victorian Branch)' => group_names.greens.vic,
      'GRN-TAS Australian Greens, Tasmanian Branch' => group_names.greens.tas,
      'GRN - FED' => group_names.greens.federal,
      'GRN - VIC' => group_names.greens.vic,
      'GRN - WA' => group_names.greens.wa,
      'Australian Greens, Northern Territory Branch' => group_names.greens.nt,
      'Australian Greens (South Australia)' => group_names.greens.sa,
      'Australian Greens - Victoria' => group_names.greens.vic,
      'Australian Greens, Tasmanian Branch' => group_names.greens.tas,
      'The Australian Greens Victoria' => group_names.greens.vic,
      # Small Parties
      'Liberal Democratic Party (QLD Branch)' => 'Liberal Democratic Party',
      'Liberal Democratic Party (Victoria Branch)' => 'Liberal Democratic Party',
      'Liberal Democratic Party' => 'Liberal Democratic Party',
      'Liberal Democratic Party (ACT Branch)' => 'Liberal Democratic Party',
      'Liberal Democratic Party (NSW Branch)' => 'Liberal Democratic Party',
      "Pauline Hanson's One Nation" => "Pauline Hanson's One Nation",
      "Pauline Hanson's One Nation (ONA)" => "Pauline Hanson's One Nation",
      'Shooters, Fishers and Farmers Party' => 'Shooters, Fishers and Farmers Party',
      'CEC' => 'Citizens Party',
      'Sustainable Australia Party - Stop Overdevelopment / Corruption' => 'Sustainable Australia Party',
      'Centre Alliance' => 'Centre Alliance',
      'The Local Party of Australia'  => 'The Local Party of Australia',
      'KAP' => 'Katter Australia Party',
      'Katter Australia Party' => 'Katter Australia Party',
      "Katter's Australian Party" => 'Katter Australia Party',
      'Australian Conservatives'  => 'Australian Conservatives',
      'Australian Conservatives (NSW)'  => 'Australian Conservatives',
      'Australian Conservatives (Qld)'  => 'Australian Conservatives',
      'Australian Conservatives (Vic)'  => 'Australian Conservatives',
      'Australian Conservatives ACP'  => 'Australian Conservatives',
      # Other
      'climate 200 Pty Ltd' => 'Climate 200 Pty Ltd',
      'climate 200 pty ltd' => 'Climate 200 Pty Ltd',
      'Climate 200 Pty Ltd' => 'Climate 200 Pty Ltd',
      'CLIMATE 200 PTY LTD' => 'Climate 200 Pty Ltd',
      'CLIMATE 200 PTY LIMITED' => 'Climate 200 Pty Ltd',
      'Climate 200' => 'Climate 200 Pty Ltd',
      'Climate 200 PTY LTD' => 'Climate 200 Pty Ltd',
      'Climate 200 Pty Limited' => 'Climate 200 Pty Ltd',
      'Climate 200 pty ltd' => 'Climate 200 Pty Ltd',
      'Climate200' => 'Climate 200 Pty Ltd',
      'ACTU' => 'Australian Council of Trade Unions',
      "It's Not A Race Limited" => "It's Not a Race Limited",
      'It is Not A Race Limited' => "It's Not a Race Limited",
      "It's Not a Race Limited" => "It's Not a Race Limited",
      "It's Note A Race Limited" => "It's Not a Race Limited",
      'Australian Youth Climate Coalition' => 'Australian Youth Climate Coalition',
      'Advance Aus Limited' => 'Advance Australia',
      'Advance Australia' => 'Advance Australia',
      'Australian Hotels Association (N.S.W.)' => 'Australian Hotels Association',
      'Australian Hotels Association (SA Branch)' => 'Australian Hotels Association',
      'Australian Hotels Association - Federal Office' => 'Australian Hotels Association',
      'GetUp' => 'Get Up Limited',
      'GetUp Limited' => 'Get Up Limited',
      'GetUp Ltd' => 'Get Up Limited',
      'Alpha Diversification Pty Ltd' => 'Alpha Diversification Pty Ltd',
      'Actus Services Pty Ltd' => 'Actus Services Pty Ltd',
      'United Australia Party' => 'United Australia Party',
      'United Australia Federal' => 'United Australia Party',
      'Registered Clubs Association of NSW (T/As ClubsNSW)' => 'Registered Clubs Association of NSW (T/As ClubsNSW)',
      'Registered Clubs Association of NSW (t/as Clubsnsw)' => 'Registered Clubs Association of NSW (T/As ClubsNSW)',
      'Cmax Advisory' => 'CMAX Advisory',
      'CMAX Advisory' => 'CMAX Advisory',
      'The Pharmacy Guild of Australia' => 'The Pharmacy Guild of Australia',
      'Pharmacy Guild of Australia' => 'The Pharmacy Guild of Australia',
      'The Pharmacy Guild' => 'The Pharmacy Guild of Australia',
      'Arafura Rare Earths' => 'Arafura Resources',
      'Arafura Resources' => 'Arafura Resources',
    }
  end

  let(:mapper) { MapGroupNamesAecDonations.new }

  describe '#initialize' do
    it 'initializes with a name' do
      service = described_class.new('Test Name', nil, mapper)
      expect(service.name).to eq('Test Name')
    end

    xit 'uses the names from the combo', :aggregate_failures do
      name_combos.each do |name, expected|
        service = described_class.new(name)
        expect(service.name).to eq(expected)
      end
    end
  end

  describe '.call' do
    context 'when the mapper is AEC Donations' do
      let(:mapper) { MapGroupNamesAecDonations.new }

      context 'when the group does not already exist' do
        it 'creates a group with the given name' do
          expect { described_class.call('Test Name', mapper:) }.to change(Group, :count).by(1)

          expect(Group.last.name).to eq('Test Name')
        end

        it 'creates a group with the given name and business number' do
          expect { described_class.call('Test Name', business_number: 'ABN: 123 456 789', mapper:) }.to change(Group, :count).by(1)

          expect(Group.last.name).to eq('Test Name')
          expect(Group.last.business_number).to eq('123456789')
        end
      end

      context 'when the group already exists' do
        let(:existing_name) { 'Existing Group' }
        let(:business_number) { '123456789' }
        let(:business_number_different_format) { 'ABN: 123 456 789' }

        before do
          Group.create(name: existing_name, business_number: business_number)
        end

        context 'when given only the identical name' do
          it 'does not create a new group' do
            expect { described_class.call(existing_name, mapper:) }.not_to(change(Group, :count))
          end
        end

        context 'when given the identical name and business number' do
          it 'does not create a new group' do
            expect { described_class.call(existing_name, business_number: business_number_different_format, mapper:) }.not_to(change(Group, :count))
          end
        end
      end
    end

    describe 'when the mapper is General' do
      let(:mapper) { MapGroupNamesGeneral.new }

      it 'creates a group with the given name' do
        expect { described_class.call('GREENS LIST CLERKING SERVICES', mapper:) }.to change(Group, :count).by(1)

        expect(Group.last.name).to eq('Greens List Clerking Services')
      end
    end
  end
end
