class OpenAustralia::MaxKnownPersonId
  def self.call = new.call

  def call
    roster_person_ids.map(&:to_i).max
  end

  private

  def roster_person_ids
    (api_client.get_representatives + api_client.get_senators).map { |term| term['person_id'] }
  end

  def api_client
    @api_client ||= OpenAustralia::ApiClient.new
  end
end
