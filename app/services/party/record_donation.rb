class Party::RecordDonation
  attr_reader :name

  def initialize(name)
    # @name = sanitized_name
    @name = mapping[name] || name
  end

  def self.call(name)
    new(name).call
  end

  def call
    group = Group.find_or_create_by(name:)
    # TODO: add donation
  end

  def mapping
    {
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
      # ALP
      'ALP-NSW' => 'Australian Labor Party',
      'Australian Labor Party (State of Queensland)' => 'Australian Labor Party',
      'Australian Labor Party (Western Australian Branch)' => 'Australian Labor Party',
      'Australian Labor Party (N.S.W. Branch)' => 'Australian Labor Party',
      'Australian Labor Party (ALP)' => 'Australian Labor Party',
      'Australian Labor Party (Victorian Branch)' => 'Australian Labor Party',
      'Australian Labor Party (Northern Territory) Branch' => 'Australian Labor Party',
      'ALP-SA' => 'Australian Labor Party',
      'ALP-FED' => 'Australian Labor Party',
      'Australian Labor Party (South Australian Branch)' => 'Australian Labor Party',
      # Greens
      'Australian Greens' => 'The Greens',
      'The Greens (WA) Inc' => 'The Greens',
      'The Australian Greens - Victoria' => 'The Greens',
      'Queensland Greens' => 'The Greens',
      'GRN-TAS Australian Greens, Tasmanian Branch' => 'The Greens',
      'Australian Greens, Northern Territory Branch' => 'The Greens',
      # Small Parties
      'Liberal Democratic Party (QLD Branch)' => 'Liberal Democratic Party',
      'Liberal Democratic Party (Victoria Branch)' => 'Liberal Democratic Party',
      "Pauline Hanson's One Nation" => "Pauline Hanson's One Nation",
      "Shooters, Fishers and Farmers Party" => "Shooters, Fishers and Farmers Party",
      'CEC' => 'Citizens Party',
      'Sustainable Australia Party - Stop Overdevelopment / Corruption' => 'Sustainable Australia Party',
      'Centre Alliance' => 'Centre Alliance',
      'The Local Party of Australia'  => 'The Local Party of Australia',
      # Independents
      'David Pocock' => 'David Pocock Campaign',
      'David Pocock - Davi' => 'David Pocock Campaign',
      'Zali Steggall' => 'Zali Steggall Campaign',
      'Kim for Canberra' => 'Kim for Canberra',
      # Other
      'climate 200 Pty Ltd' => 'Climate 200',
      'Climate 200 Pty Ltd' => 'Climate 200',
      'CLIMATE 200 PTY LTD' => 'Climate 200',
      'ACTU' => 'Australian Council of Trade Unions',
      "It's Not A Race Limited" => "It's Not a Race Limited",
      'Australian Youth Climate Coalition' => 'Australian Youth Climate Coalition',
    }
  end

  def sanitized_name
    name.gsub(/PTY/, 'Pty')
        .gsub(/LTD/, 'Ltd')
        .gsub(/pty/, 'Pty')
        .gsub(/ltd/, 'Ltd')
        .gsub(/LIMITED/, 'Limited')
  end
end