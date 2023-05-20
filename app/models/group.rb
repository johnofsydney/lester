class Group < ApplicationRecord
  NAME_MAPPING = {
      # Coalition
      'Liberal Party of Australia' => 'The Coalition',
      'Liberal Party of Australia (S.A. Division)' => 'The Coalition',
      'Liberal Party of Australia - Tasmanian Division' => 'The Coalition',
      'Liberal Party of Australia, NSW Division' => 'The Coalition',
      'Liberal National Party of Queensland' => 'The Coalition',
      'LIB-TAS' => 'The Coalition',
      'LIB-NSW' => 'The Coalition',
      'LIB-FED' => 'The Coalition',
      'LIB-VIC' => 'The Coalition',
      'LIB-SA' => 'The Coalition',
      'National Party of Australia' => 'The Coalition',
      'Liberal Party of Australia (Victorian Division)' => 'The Coalition',
      'Liberal Party (W.A. Division) Inc' => 'The Coalition',
      'National Party of Australia - N.S.W.' => 'The Coalition',
      'Liberal Party of Australia - ACT Division' => 'The Coalition',
      'Country Liberal Party (NT)' => 'The Coalition',
      'LIB - NSW' => 'The Coalition',
      'LIB VIC' => 'The Coalition',
      'LIB-ACT' => 'The Coalition',
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
      # Greens
      'Australian Greens' => 'The Greens',
      'The Greens (WA) Inc' => 'The Greens',
      'The Australian Greens - Victoria' => 'The Greens',
      'Queensland Greens' => 'The Greens',
      'GRN-TAS Australian Greens, Tasmanian Branch' => 'The Greens',
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


  has_many :memberships
  has_many :people, through: :memberships

  has_many :transfers, as: :giver
  has_many :transfers, as: :taker

  def incoming_transfers = Transfer.includes(:giver).where(taker_id: self.id).order(amount: :desc)
  def outgoing_transfers = Transfer.includes(:taker).where(giver_id: self.id).order(amount: :desc)

  def incoming_sum = Transfer.where(taker: self).sum(:amount)
  def outgoing_sum = Transfer.where(giver: self).sum(:amount)
  def net_sum = incoming_sum - outgoing_sum

  def people_transfers
    incoming_transfers = []
    outgoing_transfers = []
    self.people.each do |person|
      incoming_transfers << person.transfers.where(taker: person)
      outgoing_transfers << person.transfers.where(giver: person)
    end

    OpenStruct.new(
      incoming_transfers: incoming_transfers.flatten,
      outgoing_transfers: outgoing_transfers.flatten
    )
  end
end
