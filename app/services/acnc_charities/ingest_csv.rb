class AcncCharities::IngestCsv
  def self.perform
    new.perform
  end

  def perform
    response = AcncCharities::CsvDownloader.new.download(url)
    return unless response && response[:body]

    csv = CSV.parse(response[:body], headers: true)
    category = Group.find_or_create_by(name: 'Charity', category: true)

    csv.map{|row| {name: row['Charity_Legal_Name'], abn: row['ABN']} }
       .reject{|row| row[:abn].nil? }
       .reject{|row| row[:name].nil? }
       .each_with_index do |row, index|
        # possibly add a small delay between jobs
        # Each operation is not very heavy, but there are a thousands of rows to process,
        # delay = (index % 10 )+ 1
        RecordSingleCharityGroupJob.perform_async(row[:name], row[:abn], category.id)
       end
  end

  def url
    "https://data.gov.au/data/dataset/b050b242-4487-4306-abf5-07ca073e5594/resource/8fb32972-24e9-4c95-885e-7140be51be8a/download/datadotgov_main.csv"
  end
end