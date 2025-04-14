class LinkedinProfileGetterJob
  include Sidekiq::Job

  def perform(person_id)
    person = Person.find_by(id: person_id)
    return unless person

    # Check if the person has a LinkedIn URL
    if person.linkedin_url.present?
      # Perform the LinkedIn profile ingestion
      LinkedInProfileGetter.new(person).perform
    else
      Rails.logger.info("Person with ID #{person_id} does not have a LinkedIn URL.")
    end
  rescue StandardError => e
    Rails.logger.error("Error processing LinkedIn profile for Person ID #{person_id}: #{e.message}")
  end
end
