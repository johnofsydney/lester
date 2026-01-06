class AuLobbyists::IngestLobbyists
  def self.call
    new.call
  end

  def call
    # download the XLSX file and convert to CSVs
    downloader = AuLobbyists::FileDownloader.new
    return unless downloader.call

    importer = AuLobbyists::CsvImporter.new
    importer.import_clients # clients of lobbyist organisations, linking to lobbyist organisations
    importer.import_lobbyist_people # employees of lobbyist organisations
    importer.import_lobbyist_organisations # will catch any organisations not already recorded
  end
end