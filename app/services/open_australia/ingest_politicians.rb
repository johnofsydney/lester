class OpenAustralia::IngestPoliticians
  def self.call = new.call

  def call
    api = OpenAustralia::ApiClient.new

    api.get_representatives.each do |row|
      OpenAustralia::ImportPoliticianRowJob.perform_async(row['person_id'].to_s, '1')
    end

    api.get_senators.each do |row|
      OpenAustralia::ImportPoliticianRowJob.perform_async(row['person_id'].to_s, '2')
    end
  end
end
