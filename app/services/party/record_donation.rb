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
      'Liberal Party of Australia' => 'The Coalition',
      'Liberal Party of Australia (S.A. Division)' => 'The Coalition',
      'Liberal Party of Australia - Tasmanian Division' => 'The Coalition',
      'Liberal Party of Australia, NSW Division' => 'The Coalition',
      'Liberal National Party of Queensland' => 'The Coalition',
      'LIB-TAS' => 'The Coalition',
      'LIB-NSW' => 'The Coalition',
      'LIB-FED' => 'The Coalition',
      'LIB-VIC' => 'The Coalition',
      'ALP-NSW' => 'Australian Labor Party',
      'climate 200 Pty Ltd' => 'Climate 200',
      'Climate 200 Pty Ltd' => 'Climate 200',
      'National Party of Australia - N.S.W.' => 'The Coalition',
      'Australian Labor Party (N.S.W. Branch)' => 'Australian Labor Party',
      'Australian Labor Party (ALP)' => 'Australian Labor Party',
      'Australian Labor Party (Victorian Branch)' => 'Australian Labor Party',
      'Liberal Party of Australia (Victorian Division)' => 'The Coalition',
      'Liberal Party (W.A. Division) Inc' => 'The Coalition',
      'Liberal Democratic Party (QLD Branch)' => 'Liberal Democratic Party',
      'Australian Labor Party (State of Queensland)' => 'Australian Labor Party',
      'Australian Labor Party (Western Australian Branch)' => 'Australian Labor Party',
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