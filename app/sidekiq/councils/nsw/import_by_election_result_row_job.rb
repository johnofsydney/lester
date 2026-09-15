# Imports one NSW council by-election/countback result: records the elected candidate as a Person
# with an undated Councillor Membership, and appends a raw, dated observation to
# Person#council_election_data (see People::RecordCouncilElectionData). NSWEC's own archive page
# doesn't distinguish a by-election from a countback the way VEC's does -- both are recorded
# identically here.
#
# `council_description` is heading free text with the date/kind/ward suffix already stripped by
# Councils::Nsw::ByElectionIndexParser as best effort -- not guaranteed to exactly match an
# existing council's canonical Group name across two decades of inconsistent NSWEC wording.
class Councils::Nsw::ImportByElectionResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  STATE = :nsw
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(lb_id, report_url, council_description)
    page = Councils::PageDownloader.call(report_url)
    raise "Failed to download NSW by-election/countback result page: #{report_url}" if page.blank?

    result = Councils::Nsw::ByElectionResultsParser.call(page)
    return if result.blank? # not yet declared -- nothing to record yet

    council = Groups::RecordGroup.call(council_description)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "NSW Electoral Commission by-election/countback declared results (#{report_url})"
    result[:candidates].each do |candidate|
      record_candidate(council:, candidate:, declared_date: result[:declared_date], evidence:, lb_id:, source_url: report_url)
    end
    IngestSourceStatus.record_success(self.class.name)
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::ImportByElectionResultRowJob(#{lb_id}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end

  private

  def record_candidate(council:, candidate:, declared_date:, evidence:, lb_id:, source_url:)
    person = RecordCandidatePerson.call(name: candidate[:name], scope_group: council)

    Group::RecordRow.new(group: council, person:, title: 'Councillor', evidence:).call
    record_election_data(person:, council:, declared_date:, lb_id:, source_url:)
  end

  def record_election_data(person:, council:, declared_date:, lb_id:, source_url:)
    People::RecordCouncilElectionData.call(
      person:,
      observation: {
        state: STATE,
        council_name: council.name,
        council_slug: council.name.parameterize,
        cycle: lb_id,
        declared_date:,
        party: nil,
        source_url:
      }
    )
  end
end
