class OpenAustralia::IngestCurrentPoliticians
  def self.call = new.call

  def call
    person_ids.each { |person_id| OpenAustralia::IngestPersonJob.perform_async(person_id) }
  end

  private

  def person_ids
    (roster_person_ids + db_current_person_ids).uniq
  end

  def roster_person_ids
    (api_client.get_representatives + api_client.get_senators).map { |term| term['person_id'] }.uniq
  end

  def db_current_person_ids
    Person.where(id: Membership.person_currently_in_federal_parliament.select(:member_id)).filter_map(&:open_australia_id)
  end

  def api_client
    @api_client ||= OpenAustralia::ApiClient.new
  end
end
