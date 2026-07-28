class OpenAustralia::IngestCurrentPoliticians
  def self.call = new.call

  def call
    person_ids.each { |person_id| OpenAustralia::IngestPersonJob.perform_async(person_id) }
  end

  private

  def person_ids
    (api_client.get_representatives + api_client.get_senators).map { |term| term['person_id'] }.uniq
  end

  def api_client
    @api_client ||= OpenAustralia::ApiClient.new
  end
end
