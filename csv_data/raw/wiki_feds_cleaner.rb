require 'csv'
require 'pry'

class Parser
  FEDERAL_ELECTION_DATES = {
    '1993' => Date.new(1993, 3, 13),
    '1996' => Date.new(1996, 3, 2),
    '1998' => Date.new(1998, 10, 3),
    '2001' => Date.new(2001, 11, 10),
    '2004' => Date.new(2004, 10, 9),
    '2007' => Date.new(2007, 11, 24),
    '2010' => Date.new(2010, 8, 21),
    '2013' => Date.new(2013, 9, 7),
    '2016' => Date.new(2016, 7, 2),
    '2019' => Date.new(2019, 5, 18),
    '2022' => Date.new(2022, 5, 22),
  }

  def self.parsed_row(row, level)
    name = parse_person_name(row[0])
    party = parse_party_name(row[1], level)
    electorate = row[2]
    state = row[3].upcase
    start_date = parse_start_date(row[4])
    end_date = parse_end_date(row[4])

    [name, party, electorate, state, start_date, end_date]
  rescue => e
    puts "Error parsing row: #{row}"
    p e.inspect
    # binding.pry
    []
  end

  def self.parse_name(name)
    name.gsub(/\(.+\)/, '')
        .gsub(/\[.+/, '')
        .strip
  end

  def self.parse_party_name(name, level)
    parse_name(name) + level
  end

  def self.parse_person_name(name)
    parse_name(name)
  end

  def self.parse_start_date(date)

    start_year = date.tr('–', '-').tr('—', '-')
                     .split('-').first
                     .strip.to_s

    FEDERAL_ELECTION_DATES[start_year] || Date.new(start_year.to_i, 1, 1) || "XX #{start_year} XX"
  end

  def self.parse_end_date(date)
    return '' if date.include?('current')
    return '' if date.include?('present')

    end_year = date.tr('–', '-').tr('—', '-')
                     .split('-').last
                     .strip.to_s

    return '' if end_year == 'current'
    return '' if end_year == 'present'

    FEDERAL_ELECTION_DATES[end_year] || Date.new(end_year.to_i, 1, 1) || "XX #{end_year} XX"
  end

  def self.level(filename)
    case filename
    when /feds/
      ' Federal'
    end
  end
end

files_to_clean = [
  'wiki_feds_current_mps',
  'wiki_feds_ending_2019',
  'wiki_feds_ending_2022',
  'wiki_feds_current_senators',
  'wiki_feds_senators_ending_2022',
  'wiki_feds_senators_ending_2019',
]

files_to_clean.each do |filename|
  level = Parser.level(filename)

  file = filename +  '.csv'
  csv = CSV.read(file, headers: true)

  # creates an array called rows with the first row being the headers
  rows = [%w[name party electorate state start_date end_date]]

  csv.each do |row|
    rows << Parser.parsed_row(row, level)
  end

  CSV.open(filename + '_cleaned' + '.csv', 'w') do |csv|
    rows.each do |row|
      csv << row
    end
  end
end

true