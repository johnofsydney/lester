class Exports::UploadSummary
  KEY = 'summary.json'.freeze

  def self.call
    new.call
  end

  def call
    Exports::S3Client.upload(KEY, body)
  end

  private

  def body
    { groups: Group.count, people: Person.count }.to_json
  end
end
