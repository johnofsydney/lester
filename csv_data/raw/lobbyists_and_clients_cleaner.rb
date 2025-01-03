require 'csv'
require 'pry'


class Parser
  def self.parse_lobbyist_name(name)
    name.split(' | ').first
  end

  def self.parse_date(date_string)
    Date.parse(date_string).to_s
  end
end

tsv = CSV.read('csv_data/raw/lobbyists_and_clients.tsv', headers: true, col_sep: "\t")

CSV.open(
  'csv_data/raw/lobbyists_and_clients_cleaned.csv',
  "w",
  write_headers: true,
  headers: ['member_group', 'group', 'start_date', 'evidence']
  ) do |csv|
    tsv.each do |row|
      csv << [
        row['name'],
        Parser.parse_lobbyist_name(row['client of']),
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