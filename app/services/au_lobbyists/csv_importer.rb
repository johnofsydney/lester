class AuLobbyists::CsvImporter
  def initialize; end

  def import_clients
    csv = CSV.read(clients_csv_path, headers: true)
    csv.each do |row|
      client_name = row["Client's Name"]&.strip
      client_abn = row["Client's ABN"]&.gsub(/\D/, '')
      start_date = row['Date Published'].strip
      lobbyist_name = row['Parent Organisation']&.strip
      lobbyist_abn = row["Organisation's ABN"]&.gsub(/\D/, '')

      AuLobbyists::ImportClientRowJob.perform_async(client_name, client_abn, start_date, lobbyist_name, lobbyist_abn)
    end
  end

  def import_lobbyist_people
    csv = CSV.read(lobbyist_people_csv_path, headers: true)
    csv.each do |row|
      person_name = row["Lobbyist's Name"]&.strip
      title = row['Job Title']&.strip
      start_date = row['Date Published'].strip
      lobbyist_name = row['Parent Organisation']&.strip
      lobbyist_abn = row["Organisation's ABN"]&.gsub(/\D/, '')

      AuLobbyists::ImportLobbyistsPeopleRowJob.perform_async(person_name, title, start_date, lobbyist_name, lobbyist_abn)
    end
  end

  def import_lobbyist_organisations
    csv = CSV.read(lobbyist_organisations_csv_path, headers: true)
    csv.each do |row|
      lobbyist_name = row['Legal Name']&.strip
      lobbyist_abn = row['ABN']&.gsub(/\D/, '')
      start_date = row['Registered On'].strip

      AuLobbyists::ImportLobbyistOrganisationsRowJob.perform_async(lobbyist_name, lobbyist_abn, start_date)
    end
  end

  def clients_csv_path
    @clients_csv_path ||= Rails.root.join('tmp/clients.csv')
  end

  def lobbyist_people_csv_path
    @lobbyist_people_csv_path ||= Rails.root.join('tmp/lobbyists.csv')
  end

  def lobbyist_organisations_csv_path
    @lobbyist_organisations_csv_path ||= Rails.root.join('tmp/organisations.csv')
  end
end