# Imports one VIC council's declared councillor election results: records each
# elected candidate as a Person with a Membership (real start_date from the "last
# updated" date on the results page), and closes out anyone previously on the
# council who wasn't returned. Unlike NSW, VEC results pages don't show party
# affiliation, so no party membership is recorded here.
class Councils::Vic::ImportCouncilResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  ELECTION_YEAR = 2024
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(council_name, council_slug)
    url = "https://www.vec.vic.gov.au/results/council-election-results/#{ELECTION_YEAR}-council-election-results/#{council_slug}"
    page = Councils::PageDownloader.call(url)
    raise "Failed to download VIC council results: #{url}" if page.blank?

    result = Councils::Vic::CouncillorResultsParser.call(page)
    return if result.blank? # not yet declared -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "Victorian Electoral Commission #{ELECTION_YEAR} council election declared results (#{url})"
    recorded_people = result[:candidates].filter_map do |candidate|
      record_candidate(council:, candidate:, declared_date: result[:declared_date], evidence:)
    end

    # Guard against closing everyone out if the page parsed but yielded no usable
    # candidates -- that's more likely a parsing problem than an empty council.
    close_departed_members(council:, recorded_people:, declared_date: result[:declared_date]) if recorded_people.present?
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::ImportCouncilResultRowJob(#{council_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

  def record_candidate(council:, candidate:, declared_date:, evidence:)
    person = People::RecordPerson.call(candidate[:name])
    return nil if person.nil?

    Group::RecordRow.new(
      group: council, person:, title: 'Councillor', evidence:, start_date: declared_date
    ).call

    person
  end

  def close_departed_members(council:, recorded_people:, declared_date:)
    still_serving_ids = recorded_people.map(&:id)

    Membership.where(group: council, member_type: 'Person', end_date: nil)
              .where.not(member_id: still_serving_ids)
              .find_each do |membership|
      membership.update!(
        end_date: declared_date,
        evidence: [membership.evidence, "Not returned in the #{ELECTION_YEAR} VIC council election"].compact.join(' / ')
      )
    end
  end
end
