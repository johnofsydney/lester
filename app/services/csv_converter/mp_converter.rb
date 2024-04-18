class CsvConverter::MpConverter
  class << self
    def mp_ingest(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
      end
    end
  end
end