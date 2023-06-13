class Group < ApplicationRecord
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

  # attr_accessor :depth, :direction # this is a temporary attribute used in the consolidation process

  def nodes(include_looser_nodes: false)
    return [people + affiliated_groups].compact.flatten.uniq unless include_looser_nodes

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


    outgoing_transfers.map(&:taker) +
    incoming_transfers.map(&:giver)
    # outgoing_transfers.includes(:giver, :taker).map(&:taker) +
    # incoming_transfers.includes(:giver, :taker).map(&:giver)

  end






  NAME_MAPPING = {
    # Coalition
    'Liberal Party of Australia' => 'The Coalition',
    'Liberal Party of Australia (S.A. Division)' => 'The Coalition',
    'Liberal Party of Australia - Tasmanian Division' => 'The Coalition',
    'Liberal Party of Australia, NSW Division' => 'The Coalition',
    'Liberal National Party of Queensland' => 'The Coalition',
    'LIB-ACT' => 'The Coalition',
    'LIB-TAS' => 'The Coalition',
    'LIB-NSW' => 'The Coalition',
    'LIB-FED' => 'The Coalition',
    'LIB-VIC' => 'The Coalition',
    'LIB-SA' => 'The Coalition',
    'LIB - TAS' => 'The Coalition',
    'LIB - NSW' => 'The Coalition',
    'LIB - FED' => 'The Coalition',
    'LIB - VIC' => 'The Coalition',
    'LIB - SA' => 'The Coalition',
    'National Party of Australia' => 'The Coalition',
    'Liberal Party of Australia (Victorian Division)' => 'The Coalition',
    'Liberal Party (W.A. Division) Inc' => 'The Coalition',
    'National Party of Australia - N.S.W.' => 'The Coalition',
    'Liberal Party of Australia - ACT Division' => 'The Coalition',
    'Country Liberal Party (NT)' => 'The Coalition',
    'LIB VIC' => 'The Coalition',
    'LIB-FED Liberal Party of Australia (Menzies Research Centre)' => 'The Coalition',
    'LIB-WA' => 'The Coalition',
    'LNP-QLD' => 'The Coalition',
    'Lib-Fed' => 'The Coalition',
    'Lib-NSW' => 'The Coalition',
    'Liberal National Party' => 'The Coalition',
    'Liberal National Party (LNP-QLD)' => 'The Coalition',
    'Liberal National Party LNP QLD' => 'The Coalition',
    'Liberal National Party of QLD' => 'The Coalition',
    'Liberal Party (W.A. Division) Inc. (LIB-WA)' => 'The Coalition',
    'Liberal Party NSW Division' => 'The Coalition',
    'Liberal Party of Australia (LIB-FED)' => 'The Coalition',
    'Liberal Party of Australia (NSW Division)' => 'The Coalition',
    'Liberal Party of Australia (SA Division)' => 'The Coalition',
    'Liberal Party of Australia (SA Division) (LDP-SA)' => 'The Coalition',
    'Liberal Party of Australia (WA Division)' => 'The Coalition',
    'Liberal Party of Australia (WA) (LIB-WA)' => 'The Coalition',
    'Liberal Party of Australia LIB NSW' => 'The Coalition',
    'Liberal Party of Australia NSW Division' => 'The Coalition',
    'The Liberal Party of Australia (LIB-FED)' => 'The Coalition',
    'NAT - NSW' => 'The Coalition',
    'NAT-FED' => 'The Coalition',
    'NAT-NSW' => 'The Coalition',
    'National Party of Australia (NAT-FED)' => 'The Coalition',
    'National Party of Australia (WA) Inc' => 'The Coalition',
    'National Party of Australia - Victoria' => 'The Coalition',
    'National Party of Australia NAT NSW' => 'The Coalition',
    'Country Liberals (Northern Territory)' => 'The Coalition',
    'LIB - WA' => 'The Coalition',
    'LIB FED' => 'The Coalition',
    'LIB NSW' => 'The Coalition',
    'LIB-FEC' => 'The Coalition',
    'LIB-VIC Kooyong 200 Club' => 'The Coalition',
    'LIB-WA Liberal Party (WA Division Inc)' => 'The Coalition',
    'LNP - QLD' => 'The Coalition',
    'Liberal National Party of Queensland - LNP-QLD' => 'The Coalition',
    'Liberal National Party of Queensland - Maiwar' => 'The Coalition',
    'Liberal Part of Australia SA Division - Colton' => 'The Coalition',
    'Liberal Part of Australia SA Division - Dunstan' => 'The Coalition',
    'Liberal Part of Australia SA Division - Unley' => 'The Coalition',
    'Liberal Part of Australia SA Division- Dunstan' => 'The Coalition',
    'Liberal Party NSW (LIB-NSW)' => 'The Coalition',
    'Liberal Party VIC Division' => 'The Coalition',
    'Liberal Party of Australia (Federal Secretariat)' => 'The Coalition',
    'Liberal Party of Australia (VIC Division) (paid to Enterprise Victoria)' => 'The Coalition',
    'Liberal Party of Australia - LIB-FED' => 'The Coalition',
    'Liberal Party of Australia - LIB-NSW' => 'The Coalition',
    'Liberal Party of Australia - LIB-SA' => 'The Coalition',
    'Liberal Party of Australia - LIB-TAS' => 'The Coalition',
    'Liberal Party of Australia - LIB-VIC' => 'The Coalition',
    'Liberal Party of Australia Federal Forum/LIB-NSW' => 'The Coalition',
    'Liberal Party of Australia LIB-FED' => 'The Coalition',
    'Liberal Party of Australia NSW Division - Bega' => 'The Coalition',
    'Liberal Party of Australia, NSW Division (LIB-NSW)' => 'The Coalition',
    'Liberal Party of Australia/LIB-NSW' => 'The Coalition',
    'NAT-WA National Party of Australia (WA) Inc' => 'The Coalition',
    'National Party of Australia - NAT-FED' => 'The Coalition',
    'National Party of Australia - NAT-NSW' => 'The Coalition',
    'National Party of Australia - NSW' => 'The Coalition',
    'National Party of Victoria (NAT-VIC)' => 'The Coalition',
    'The Liberal Party of Australia - Victoria Division' => 'The Coalition',
    'The Nationals NAT-FED' => 'The Coalition',
    # ALP
    'ALP-NSW' => 'Australian Labor Party',
    'WA Labor (ALP-WA)' => 'Australian Labor Party',
    'The Australian Labour Party National Secretariat' => 'Australian Labor Party',
    'ALP - NSW' => 'Australian Labor Party',
    'ALP National (ALP-FED)' => 'Australian Labor Party',
    'ALP-QLD' => 'Australian Labor Party',
    'ALP-VIC' => 'Australian Labor Party',
    'Australian Labor Party (State of Queensland)' => 'Australian Labor Party',
    'Australian Labor Party (Western Australian Branch)' => 'Australian Labor Party',
    'Australian Labor Party (N.S.W. Branch)' => 'Australian Labor Party',
    'Australian Labor Party (ALP)' => 'Australian Labor Party',
    'Australian Labor Party (Victorian Branch)' => 'Australian Labor Party',
    'Australian Labor Party (Northern Territory) Branch' => 'Australian Labor Party',
    'ALP-SA' => 'Australian Labor Party',
    'ALP-FED' => 'Australian Labor Party',
    'Australian Labor Party (South Australian Branch)' => 'Australian Labor Party',
    'Australian Labor Party (ACT Branch)' => 'Australian Labor Party',
    'Australian Labor Party (ALP-FED)' => 'Australian Labor Party',
    'Australian Labor Party (Northern Territory Branch)' => 'Australian Labor Party',
    'Australian Labor Party (Victoria Branch) (ALP - VIC)' => 'Australian Labor Party',
    'Australian Labor Party (Western Australia Branch) (ALP-WA)' => 'Australian Labor Party',
    'CLP-NT' => 'Australian Labor Party',
    'Australian Labor Party (NSW Branch)'  => 'Australian Labor Party',
    'Australian Labor Party (NSW)'  => 'Australian Labor Party',
    'Australian Labor Party (Queensland)'  => 'Australian Labor Party',
    'Australian Labor Party (State of Queensland) / ALP-QLD'  => 'Australian Labor Party',
    'Australian Labor Party (Tasmanian Branch)'  => 'Australian Labor Party',
    'Australian Labor Party (Western Australia Branch)'  => 'Australian Labor Party',
    'Australian Labor Party - ALP-FED'  => 'Australian Labor Party',
    'Australian Labor Party - ALP-NSW'  => 'Australian Labor Party',
    'Australian Labor Party - ALP-QLD'  => 'Australian Labor Party',
    'Australian Labor Party - ALP-SA'  => 'Australian Labor Party',
    'Australian Labor Party - ALP-VIC'  => 'Australian Labor Party',
    'Australian Labor Party Victorian Branch'  => 'Australian Labor Party',
    'ALP - FED'  => 'Australian Labor Party',
    'ALP - SA'  => 'Australian Labor Party',
    'ALP - TAS'  => 'Australian Labor Party',
    'ALP - VIC'  => 'Australian Labor Party',
    'ALP - WA'  => 'Australian Labor Party',
    'ALP NSW BRANCH'  => 'Australian Labor Party',
    'ALP NSW Branch'  => 'Australian Labor Party',
    'ALP National Secretaria'  => 'Australian Labor Party',
    'ALP National Secretariat'  => 'Australian Labor Party',
    'ALP National Secretariat/ALP-FED'  => 'Australian Labor Party',
    'ALP New South Wales Branch/ALP-NSW'  => 'Australian Labor Party',
    'ALP QLD'  => 'Australian Labor Party',
    'ALP QLD - Mulgrave'  => 'Australian Labor Party',
    'ALP QLD - South Brisbane'  => 'Australian Labor Party',
    'ALP VIC Branch'  => 'Australian Labor Party',
    'ALP-ACT'  => 'Australian Labor Party',
    'ALP-FED Federal Labor Business Forum'  => 'Australian Labor Party',
    'ALP-SA Australian Labor Party (South Australian Branch)'  => 'Australian Labor Party',
    'ALP-TAS'  => 'Australian Labor Party',
    'ALP-WA'  => 'Australian Labor Party',
    'ALP-WA Australian Labor Party (Western Australian Branch)'  => 'Australian Labor Party',
    'Country Labor Party'  => 'Australian Labor Party',
    'Country Labor Party - CLR-NSW'  => 'Australian Labor Party',
    # Greens
    'Australian Greens' => 'The Greens',
    'The Greens (WA) Inc' => 'The Greens',
    'The Australian Greens - Victoria' => 'The Greens',
    'Queensland Greens' => 'The Greens',
    'The Australian Greens (GRN-VIC) (Victorian Branch)' => 'The Greens',
    'GRN-TAS Australian Greens, Tasmanian Branch' => 'The Greens',
    'GRN - FED' => 'The Greens',
    'GRN - VIC' => 'The Greens',
    'GRN - WA' => 'The Greens',
    'Australian Greens, Northern Territory Branch' => 'The Greens',
    'Australian Greens (South Australia)' => 'The Greens',
    'Australian Greens - Victoria' => 'The Greens',
    'Australian Greens, Tasmanian Branch' => 'The Greens',
    'The Australian Greens Victoria' => 'The Greens',
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
