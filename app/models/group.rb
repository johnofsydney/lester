class Group < ApplicationRecord

  NAMES = OpenStruct.new(
            coalition: OpenStruct.new(
              federal: 'The Coalition (Federal)',
              nsw: 'The Coalition (NSW)',
            ),
            liberals: OpenStruct.new(
              federal: 'Liberals (Federal)',
              nsw: 'Liberals (NSW)',
              qld: 'Liberal National Party (QLD)',
              sa: 'Liberals (SA)',
              vic: 'Liberals (VIC)',
              tas: 'Liberals (TAS)',
              wa: 'Liberals (WA)',
              act: 'Liberals (ACT)',
              nt: 'Country Liberal Party (NT)',
            ),
            nationals: OpenStruct.new(
              federal: 'Nationals (Federal)',
              nsw: 'Nationals (NSW)',
              qld: 'Liberal National Party (QLD)',
              sa: 'Nationals (SA)',
              vic: 'Nationals (VIC)',
              tas: 'Nationals (TAS)',
              wa: 'Nationals (WA)',
              act: 'Nationals (ACT)',
              nt: 'Country Liberal Party (NT)',
            ),
            labor: OpenStruct.new(
              federal: 'ALP (Federal)',
              nsw: 'ALP (NSW)',
              qld: 'ALP (QLD)',
              sa: 'ALP (SA)',
              vic: 'ALP (VIC)',
              tas: 'ALP (TAS)',
              wa: 'ALP (WA)',
              act: 'ALP (ACT)',
              nt: 'ALP (NT)',
            ),
            greens: OpenStruct.new(
              federal: 'The Greens (Federal)',
              nsw: 'The Greens (NSW)',
              qld: 'The Greens (QLD)',
              sa: 'The Greens (SA)',
              vic: 'The Greens (VIC)',
              tas: 'The Greens (TAS)',
              wa: 'The Greens (WA)',
              act: 'The Greens (ACT)',
              nt: 'The Greens (NT)',
            )
          )


  include TransferMethods

  has_many :memberships, dependent: :destroy
  has_many :people, through: :memberships

  has_many :affiliations_as_owning_group, class_name: 'Affiliation', foreign_key: 'owning_group_id', dependent: :destroy
  has_many :affiliations_as_sub_group, class_name: 'Affiliation', foreign_key: 'sub_group_id', dependent: :destroy
  has_many :sub_groups, through: :affiliations_as_owning_group, source: :sub_group
  has_many :owning_groups, through: :affiliations_as_sub_group, source: :owning_group

  # these are a bit weird, hence the transfers method below
  has_many :outgoing_transfers, class_name: 'Transfer', foreign_key: 'giver_id', as: :giver
  has_many :incoming_transfers, class_name: 'Transfer', foreign_key: 'taker_id'

  accepts_nested_attributes_for :memberships, allow_destroy: true

  def nodes(include_looser_nodes: false)
    # return people.includes([memberships: [:group, :person]]) # excludes affiliated groups

    return [people + affiliated_groups].compact.flatten.uniq unless include_looser_nodes # TODO work on includes / bullet

    [people + affiliated_groups + other_edge_ends].compact.flatten.uniq
  end

  def affiliated_groups
    owning_groups + sub_groups
  end


  def transfers
    OpenStruct.new(
      incoming: Transfer.where(taker: self).order(amount: :desc),
      outgoing: Transfer.where(giver: self, giver_type: 'Group').order(amount: :desc)
    )
  end

  def other_edge_ends
    # if a connection is not so strong as to be a relationship in the application
    # we can consider it an 'other' edge, so far, these are only transfers
    # at the end of an edge, there is a node,
    # at the end of a given transfer is the taker of that transfer
    # at the end of a received transfer is the giver of that transfer

    # looser nodes is too loose for looking at a list of associated people and groups, it catches too many.
    # try it for the degrees of seperation between two groups / two people / person & group


    outgoing_transfers.map(&:taker) +
    incoming_transfers.map(&:giver)
    # outgoing_transfers.includes(:giver, :taker).map(&:taker) +
    # incoming_transfers.includes(:giver, :taker).map(&:giver)
  end








  NAME_MAPPING = {
    # Coalition
    'Liberal Party of Australia' => NAMES.liberals.federal,
    'Liberal Party of Australia (S.A. Division)' => NAMES.liberals.sa,
    'Liberal Party of Australia - Tasmanian Division' => NAMES.liberals.tas,
    'Liberal Party of Australia, NSW Division' => NAMES.liberals.federal,
    'Liberal National Party of Queensland' => NAMES.liberals.federal,
    'LIB-ACT' => NAMES.liberals.act,
    'LIB-TAS' => NAMES.liberals.tas,
    'LIB-NSW' => NAMES.liberals.nsw,
    'LIB-FED' => NAMES.liberals.federal,
    'LIB-VIC' => NAMES.liberals.vic,
    'LIB-SA' => NAMES.liberals.sa,
    'LIB - TAS' => NAMES.liberals.tas,
    'LIB - NSW' => NAMES.liberals.nsw,
    'LIB - FED' => NAMES.liberals.federal,
    'LIB - VIC' => NAMES.liberals.vic,
    'LIB - SA' => NAMES.liberals.sa,
    'National Party of Australia' => NAMES.nationals.federal,
    'Liberal Party of Australia (Victorian Division)' => NAMES.liberals.vic,
    'Liberal Party (W.A. Division) Inc' => NAMES.liberals.wa,
    'National Party of Australia - N.S.W.' => NAMES.liberals.nsw,
    'Liberal Party of Australia - ACT Division' => NAMES.liberals.act,
    'Country Liberal Party (NT)' => NAMES.liberals.nt,
    'LIB VIC' => NAMES.liberals.vic,
    'LIB-FED Liberal Party of Australia (Menzies Research Centre)' => NAMES.liberals.federal,
    'LIB-WA' => NAMES.liberals.wa,
    'LNP-QLD' => NAMES.liberals.qld,
    'Lib-Fed' => NAMES.liberals.federal,
    'Lib-NSW' => NAMES.liberals.nsw,
    'Liberal National Party' => NAMES.liberals.federal,
    'Liberal National Party (LNP-QLD)' => NAMES.liberals.qld,
    'Liberal National Party LNP QLD' => NAMES.liberals.qld,
    'Liberal National Party of QLD' => NAMES.liberals.qld,
    'Liberal Party (W.A. Division) Inc. (LIB-WA)' => NAMES.liberals.wa,
    'Liberal Party NSW Division' => 'Liberals (NSW)',
    'Liberal Party of Australia (LIB-FED)' => NAMES.liberals.federal,
    'Liberal Party of Australia (NSW Division)' => NAMES.liberals.nsw,
    'Liberal Party of Australia (SA Division)' => NAMES.liberals.sa,
    'Liberal Party of Australia (SA Division) (LDP-SA)' => NAMES.liberals.sa,
    'Liberal Party of Australia (WA Division)' => NAMES.liberals.wa,
    'Liberal Party of Australia (WA) (LIB-WA)' => NAMES.liberals.wa,
    'Liberal Party of Australia LIB NSW' => NAMES.liberals.nsw,
    'Liberal Party of Australia NSW Division' => NAMES.liberals.nsw,
    'The Liberal Party of Australia (LIB-FED)' => NAMES.liberals.federal,
    'NAT - NSW' => NAMES.nationals.nsw,
    'NAT-FED' => NAMES.nationals.federal,
    'NAT-NSW' => NAMES.nationals.nsw,
    'National Party of Australia (NAT-FED)' => NAMES.nationals.federal,
    'National Party of Australia (WA) Inc' => NAMES.nationals.wa,
    'National Party of Australia - Victoria' => NAMES.nationals.vic,
    'National Party of Australia NAT NSW' => NAMES.nationals.nsw,
    'Country Liberals (Northern Territory)' => NAMES.liberals.nt,
    'LIB - WA' => NAMES.liberals.wa,
    'LIB FED' => NAMES.liberals.federal,
    'LIB NSW' => NAMES.liberals.nsw,
    'LIB-FEC' => NAMES.liberals.federal,
    'LIB-VIC Kooyong 200 Club' => NAMES.liberals.vic,
    'LIB-WA Liberal Party (WA Division Inc)' => NAMES.liberals.wa,
    'LNP - QLD' => NAMES.liberals.qld,
    'Liberal National Party of Queensland - LNP-QLD' => NAMES.liberals.qld,
    'Liberal National Party of Queensland - Maiwar' => NAMES.liberals.qld,
    'Liberal Part of Australia SA Division - Colton' => NAMES.liberals.sa,
    'Liberal Part of Australia SA Division - Dunstan' => NAMES.liberals.sa,
    'Liberal Part of Australia SA Division - Unley' => NAMES.liberals.sa,
    'Liberal Part of Australia SA Division- Dunstan' => NAMES.liberals.sa,
    'Liberal Party NSW (LIB-NSW)' => NAMES.liberals.nsw,
    'Liberal Party VIC Division' => NAMES.liberals.vic,
    'Liberal Party of Australia (Federal Secretariat)' => NAMES.liberals.federal,
    'Liberal Party of Australia (VIC Division) (paid to Enterprise Victoria)' => NAMES.liberals.vic,
    'Liberal Party of Australia - LIB-FED' => NAMES.liberals.federal,
    'Liberal Party of Australia - LIB-NSW' => NAMES.liberals.nsw,
    'Liberal Party of Australia - LIB-SA' => NAMES.liberals.sa,
    'Liberal Party of Australia - LIB-TAS' => NAMES.liberals.tas,
    'Liberal Party of Australia - LIB-VIC' => NAMES.liberals.vic,
    'Liberal Party of Australia Federal Forum/LIB-NSW' => NAMES.liberals.nsw,
    'Liberal Party of Australia LIB-FED' => NAMES.liberals.federal,
    'Liberal Party of Australia NSW Division - Bega' => NAMES.liberals.nsw,
    'Liberal Party of Australia, NSW Division (LIB-NSW)' => NAMES.liberals.nsw,
    'Liberal Party of Australia/LIB-NSW' => NAMES.liberals.nsw,
    'NAT-WA National Party of Australia (WA) Inc' => NAMES.liberals.wa,
    'National Party of Australia - NAT-FED' => NAMES.nationals.federal,
    'National Party of Australia - NAT-NSW' => NAMES.nationals.nsw,
    'National Party of Australia - NSW' => NAMES.nationals.nsw,
    'National Party of Victoria (NAT-VIC)' => NAMES.nationals.vic,
    'The Liberal Party of Australia - Victoria Division' => NAMES.liberals.vic,
    'The Nationals NAT-FED' => NAMES.nationals.federal,
    # ALP
    'ALP-NSW' => NAMES.labor.nsw,
    'WA Labor (ALP-WA)' => NAMES.labor.wa,
    'The Australian Labour Party National Secretariat' => NAMES.labor.federal,
    'ALP - NSW' => NAMES.labor.nsw,
    'ALP National (ALP-FED)' => NAMES.labor.federal,
    'ALP-QLD' => NAMES.labor.qld,
    'ALP-VIC' => NAMES.labor.vic,
    'Australian Labor Party (State of Queensland)' => NAMES.labor.qld,
    'Australian Labor Party (Western Australian Branch)' => NAMES.labor.wa,
    'Australian Labor Party (N.S.W. Branch)' => NAMES.labor.nsw,
    'Australian Labor Party (ALP)' => NAMES.labor.federal,
    'Australian Labor Party (Victorian Branch)' => NAMES.labor.vic,
    'Australian Labor Party (Northern Territory) Branch' => NAMES.labor.nt,
    'ALP-SA' => NAMES.labor.sa,
    'ALP-FED' => NAMES.labor.federal,
    'Australian Labor Party (South Australian Branch)' => NAMES.labor.sa,
    'Australian Labor Party (ACT Branch)' => NAMES.labor.act,
    'Australian Labor Party (ALP-FED)' => NAMES.labor.federal,
    'Australian Labor Party (Northern Territory Branch)' => NAMES.labor.nt,
    'Australian Labor Party (Victoria Branch) (ALP - VIC)' => NAMES.labor.vic,
    'Australian Labor Party (Western Australia Branch) (ALP-WA)' => NAMES.labor.nsw,
    'CLP-NT' => NAMES.labor.wa,
    'Australian Labor Party (NSW Branch)'  => NAMES.labor.nsw,
    'Australian Labor Party (NSW)'  => NAMES.labor.nsw,
    'Australian Labor Party (Queensland)'  => NAMES.labor.qld,
    'Australian Labor Party (State of Queensland) / ALP-QLD'  => NAMES.labor.qld,
    'Australian Labor Party (Tasmanian Branch)'  => NAMES.labor.tas,
    'Australian Labor Party (Western Australia Branch)'  => NAMES.labor.wa,
    'Australian Labor Party - ALP-FED'  => NAMES.labor.federal,
    'Australian Labor Party - ALP-NSW'  => NAMES.labor.nsw,
    'Australian Labor Party - ALP-QLD'  => NAMES.labor.qld,
    'Australian Labor Party - ALP-SA'  => NAMES.labor.sa,
    'Australian Labor Party - ALP-VIC'  => NAMES.labor.vic,
    'Australian Labor Party Victorian Branch'  => NAMES.labor.vic,
    'ALP - FED'  => NAMES.labor.federal,
    'ALP - SA'  => NAMES.labor.sa,
    'ALP - TAS'  => NAMES.labor.tas,
    'ALP - VIC'  => NAMES.labor.vic,
    'ALP - WA'  => NAMES.labor.wa,
    'ALP NSW BRANCH'  => NAMES.labor.nsw,
    'ALP NSW Branch'  => NAMES.labor.nsw,
    'ALP National Secretaria'  => NAMES.labor.federal,
    'ALP National Secretariat'  => NAMES.labor.federal,
    'ALP National Secretariat/ALP-FED'  => NAMES.labor.federal,
    'ALP New South Wales Branch/ALP-NSW'  => NAMES.labor.nsw,
    'ALP QLD'  => NAMES.labor.qld,
    'ALP QLD - Mulgrave'  => NAMES.labor.qld,
    'ALP QLD - South Brisbane'  => NAMES.labor.qld,
    'ALP VIC Branch'  => NAMES.labor.vic,
    'ALP-ACT'  => NAMES.labor.act,
    'ALP-FED Federal Labor Business Forum'  => NAMES.labor.federal,
    'ALP-SA Australian Labor Party (South Australian Branch)'  => NAMES.labor.sa,
    'ALP-TAS'  => NAMES.labor.tas,
    'ALP-WA'  => NAMES.labor.wa,
    'ALP-WA Australian Labor Party (Western Australian Branch)'  => NAMES.labor.wa,
    'Country Labor Party'  => NAMES.labor.nsw,
    'Country Labor Party - CLR-NSW'  => NAMES.labor.nsw,
    # Greens
    'Australian Greens' => NAMES.greens.federal,
    'The Greens (WA) Inc' => NAMES.greens.wa,
    'The Australian Greens - Victoria' => NAMES.greens.vic,
    'Queensland Greens' => NAMES.greens.qld,
    'The Australian Greens (GRN-VIC) (Victorian Branch)' => NAMES.greens.vic,
    'GRN-TAS Australian Greens, Tasmanian Branch' => NAMES.greens.tas,
    'GRN - FED' => NAMES.greens.federal,
    'GRN - VIC' => NAMES.greens.vic,
    'GRN - WA' => NAMES.greens.wa,
    'Australian Greens, Northern Territory Branch' => NAMES.greens.nt,
    'Australian Greens (South Australia)' => NAMES.greens.sa,
    'Australian Greens - Victoria' => NAMES.greens.vic,
    'Australian Greens, Tasmanian Branch' => NAMES.greens.tas,
    'The Australian Greens Victoria' => NAMES.greens.vic,
    # Small Parties
    'Liberal Democratic Party (QLD Branch)' => 'Liberal Democratic Party',
    'Liberal Democratic Party (Victoria Branch)' => 'Liberal Democratic Party',
    'Liberal Democratic Party' => 'Liberal Democratic Party',
    'Liberal Democratic Party (ACT Branch)' => 'Liberal Democratic Party',
    'Liberal Democratic Party (NSW Branch)' => 'Liberal Democratic Party',
    "Pauline Hanson's One Nation" => "Pauline Hanson's One Nation",
    "Pauline Hanson's One Nation (ONA)" => "Pauline Hanson's One Nation",
    "Shooters, Fishers and Farmers Party" => "Shooters, Fishers and Farmers Party",
    'CEC' => 'Citizens Party',
    'Sustainable Australia Party - Stop Overdevelopment / Corruption' => 'Sustainable Australia Party',
    'Centre Alliance' => 'Centre Alliance',
    'The Local Party of Australia'  => 'The Local Party of Australia',
    'KAP' => 'Katter Australia Party',
    "Katter Australia Party" => 'Katter Australia Party',
    "Katter's Australian Party" => 'Katter Australia Party',
    'Australian Conservatives'  => 'Australian Conservatives',
    'Australian Conservatives (NSW)'  => 'Australian Conservatives',
    'Australian Conservatives (Qld)'  => 'Australian Conservatives',
    'Australian Conservatives (Vic)'  => 'Australian Conservatives',
    'Australian Conservatives ACP'  => 'Australian Conservatives',
    # Independents
    'David Pocock' => 'David Pocock Campaign',
    'David Pocock - Davi' => 'David Pocock Campaign',
    'David Pocock Campaign' => 'David Pocock Campaign',
    'David Pocock Pty Ltd' => 'David Pocock Campaign',
    'David Pocock/DAVI' => 'David Pocock Campaign',
    'Zali Steggall' => 'Zali Steggall Campaign',
    'Zali Steggall Campaign' => 'Zali Steggall Campaign',
    'Kim for Canberra' => 'Kim for Canberra',
    'Helen Haines' => 'Helen Haines Campaign',
    # Other
    'climate 200 Pty Ltd' => 'Climate 200',
    'climate 200 pty ltd' => 'Climate 200',
    'Climate 200 Pty Ltd' => 'Climate 200',
    'CLIMATE 200 PTY LTD' => 'Climate 200',
    'CLIMATE 200 PTY LIMITED' => 'Climate 200',
    'Climate 200' => 'Climate 200',
    'Climate 200 PTY LTD' => 'Climate 200',
    'Climate 200 Pty Limited' => 'Climate 200',
    'Climate 200 pty ltd' => 'Climate 200',
    'Climate200' => 'Climate 200',
    'ACTU' => 'Australian Council of Trade Unions',
    "It's Not A Race Limited" => "It's Not a Race Limited",
    "It is Not A Race Limited" => "It's Not a Race Limited",
    "It's Not a Race Limited" => "It's Not a Race Limited",
    "It's Note A Race Limited" => "It's Not a Race Limited",
    'Australian Youth Climate Coalition' => 'Australian Youth Climate Coalition',
    'Advance Aus Limited' => 'Advance Australia',
    'Advance Australia' => 'Advance Australia',
    'Australian Hotels Association (N.S.W.)' => 'Australian Hotels Association',
    'Australian Hotels Association (SA Branch)' => 'Australian Hotels Association',
    'Australian Hotels Association - Federal Office' => 'Australian Hotels Association',
    'GetUp' => 'Get Up',
    'GetUp Limited' => 'Get Up',
    'GetUp Ltd' => 'Get Up',
    'Idameneo (No. 123) Pty Ptd' => 'Idameneo',
    'Idameneo (No.789) Limited' => 'Idameneo',
  }
end
