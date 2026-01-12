require 'csv'
require 'pry'

class Parser
  def self.parse_lobbyist_name(name)
    lobbyist_name = name.split(' | ').first

    # These are the INDIVIDUALS that are lobbyists, but I made them a containing group for consistency
    return 'Aiden Thomas Lobbying' if lobbyist_name == 'Aiden Thomas'
    return 'Alan Evers-Buckland Lobbying' if lobbyist_name == 'A D Evers-Buckland'
    return 'Alex Paton Lobbying' if lobbyist_name == 'PATON, ALEXANDER WILLIAM'
    return 'Alistair Webster Lobbying' if lobbyist_name == 'Alistair Webster'
    return 'Andrew Mihno Lobbying' if lobbyist_name == 'Andrew Mihno'
    return 'Barry Wallett Lobbying' if lobbyist_name == 'Barry Wallett'
    return 'Bill Forwood Lobbying' if lobbyist_name == 'Bill Forwood'
    return 'Brad Chilcott Lobbying' if lobbyist_name == 'Bradley Wayne Chilcott'
    return 'Cameron Hogan Lobbying' if lobbyist_name == 'Dr Cameron Francis Hogan'
    return 'Charles Rupert Hugh-Jones Lobbying' if lobbyist_name == 'HUGH-JONES, CHARLES RUPERT'
    return 'Charlotte Hanson Lobbying' if lobbyist_name == 'Hanson, Charlotte Adelaide'
    return 'Chris Schacht Lobbying' if lobbyist_name == 'CHRIS SCHACHT'
    return 'Christopher Drummer Lobbying' if lobbyist_name == 'Christopher Drummer'
    return 'Daniel Mcdougall Lobbying' if lobbyist_name == 'MCDOUGALL,DANIEL JOHN'
    return 'David Wawn Lobbying' if lobbyist_name == 'WAWN, DAVID ROYLE'
    return 'Grace Portolesi Lobbying' if lobbyist_name == 'ORTOLESI, GRAZIELLA'
    return 'Gregory Male Lobbying' if lobbyist_name == 'Gregory Robert Male'
    return 'Ian Israelsohn Lobbying' if lobbyist_name == 'Israelsohn, Ian Mark'
    return 'James Thomas Lobbying' if lobbyist_name == 'Thomas, James Aaron'
    return 'John Blackwell Lobbying' if lobbyist_name == 'John C Blackwell'
    return 'John Walter Kindler Lobbying' if lobbyist_name == 'Mr John Kindler'
    return 'Kate Lynch Lobbying' if lobbyist_name == 'Kate Elizabeth Lynch'
    return 'Mathew Zachariah Lobbying' if lobbyist_name == 'Mathew Zachariah'
    return 'Megan Anwyl Lobbying' if lobbyist_name == 'Megan Anwyl'
    return 'Paul Maddison Lobbying' if lobbyist_name == 'Maddison, Paul Andrew'
    return 'Stephen Mcdonald Lobbying' if lobbyist_name == 'McDonald, Stephen Brian'
    return 'Stuart Eaton Lobbying' if lobbyist_name == 'Stuart David Eaton'
    return 'Walter Secord Lobbying' if lobbyist_name == 'Walter William Secord'

    lobbyist_name
  end

  def self.parse_lobbyist_business_number(name)
    business_number = name.split(' | ').last

    return nil if business_number.match?(/[a-zA-z]/)

    business_number
  end

  def self.parse_date(date_string)
    Date.parse(date_string).to_s
  end
end

tsv = CSV.read('csv_data/raw/lobbyists_and_clients.tsv', headers: true, col_sep: "\t")

CSV.open(
  'csv_data/lobbyists_and_clients_cleaned_2025-01-02.csv',
  'w',
  write_headers: true,
  headers: ['member_group', 'abn', 'group', 'business_number', 'start_date', 'evidence']
) do |csv|
    tsv.each do |row|
      csv << [
        row['name'],
        row['abn'],
        Parser.parse_lobbyist_name(row['client of']),
        Parser.parse_lobbyist_business_number(row['client of']),
        Parser.parse_date(row['date published']),
        'https://lobbyists.ag.gov.au/register'
      ]
    end
end

# name = member_group = client
# client_of = owning_group = lobbyist
# A lobbyist is the owning group. A lobbyist can have many clients.
# Also a client can have many lobbyists, they will also be the owning group.
# The start date is from date published on the register.

true

# these groups already created on production, with sole trader person as a member of the group:
# deploy@ip-10-0-1-50:~/lester/current$ bundle exec rake lester:create_sole_trader_groups
# "Created group: Aiden Thomas Lobbying"
# "Created group: Alan Evers-Buckland Lobbying"
# "Created group: Alex Paton Lobbying"
# "Created group: Alistair Webster Lobbying"
# "Created group: Andre Haermeyer Lobbying"
# "Created group: Andrew Mihno Lobbying"
# "Created group: Baber Peters Lobbying"
# "Created group: Barry Wallett Lobbying"
# "Created group: Bill Forwood Lobbying"
# "Created group: Brad Chilcott Lobbying"
# "Created group: Cameron Hogan Lobbying"
# "Created group: Charles Rupert Hugh-Jones Lobbying"
# "Created group: Charlotte Hanson Lobbying"
# "Created group: Chris Schacht Lobbying"
# "Created group: Christopher Drummer Lobbying"
# "Created group: Daniel Mcdougall Lobbying"
# "Created group: David Wawn Lobbying"
# "Created group: Frank Banks Lobbying"
# "Created group: Grace Portolesi Lobbying"
# "Created group: Gregory Male Lobbying"
# "Created group: Ian Israelsohn Lobbying"
# "Created group: James Thomas Lobbying"
# "Created group: John Blackwell Lobbying"
# "Created group: John Crookston Lobbying"
# "Created group: John Walter Kindler Lobbying"
# "Created group: Kate Lynch Lobbying"
# "Created group: Mark Baker Lobbying"
# "Created group: Mathew Zachariah Lobbying"
# "Created group: Megan Anwyl Lobbying"
# "Created group: Paul Maddison Lobbying"
# "Created group: Stephen Mcdonald Lobbying"
# "Created group: Stuart Eaton Lobbying"
# "Created group: Walter Secord Lobbying"
