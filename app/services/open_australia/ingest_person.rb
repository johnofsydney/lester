class OpenAustralia::IngestPerson
  def self.call(person_id:) = new(person_id:).call

  def initialize(person_id:)
    @person_id = person_id.to_s
  end

  def call
    terms = fetch_terms
    return nil if terms.empty?

    person = People::RecordPerson.call(terms.last['full_name'], open_australia_id: person_id)
    person.update!(open_australia_data: terms, open_australia_data_fetched_at: Time.current)
    person
  end

  private

  attr_reader :person_id

  def fetch_terms
    (representative_terms + senator_terms).sort_by { |term| term['entered_house'] }
  end

  def representative_terms
    coerce_to_array(api_client.get_representative(person_id))
  end

  def senator_terms
    coerce_to_array(api_client.get_senator(person_id))
  end

  def coerce_to_array(response)
    response.is_a?(Array) ? response : []
  end

  def api_client
    @api_client ||= OpenAustralia::ApiClient.new
  end
end
