# Top-level ingest job for a NSW state general election's Legislative Council (LC) results -- see
# docs/plans/0011-ingest-nsw-state-politicians-design.md's LC addendum. Unlike LA, LC is one
# statewide proportional ballot, not 93 single-winner electorates -- there's no per-seat fan-out,
# just three page fetches: the statewide winners roster, the group-to-party-name mapping, and the
# full candidate roster (winners and losers, with an explicit status) used to find unsuccessful
# candidates worth gating through Councils::PartyMapper.
class NswStatePoliticians::IngestLcElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low, lock: :until_executed, on_conflict: :log, retry: 3

  EXCLUDED_STATUS = 'EXCLUDED'.freeze

  def perform(event_id = NswStatePoliticians::Elections.latest[:id])
    @event_id = event_id
    record_winners
    record_losers
    IngestSourceStatus.record_success(self.class.name)
  rescue StandardError => e
    Rails.logger.error "Error processing NswStatePoliticians::IngestLcElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end

  private

  attr_reader :event_id

  def record_winners
    winners.each do |winner|
      NswStatePoliticians::RecordLcCandidate.call(
        event_id:, name: winner[:name], party: winner[:party], elected: true,
        group_letter: winner[:group_letter], elected_at_count: winner[:elected_at_count], source_url: candidates_elected_url
      )
    end
  end

  def record_losers
    candidates.each do |candidate|
      next if candidate[:status] != EXCLUDED_STATUS

      party = group_party_names[candidate[:group_letter]]
      NswStatePoliticians::RecordLcCandidate.call(
        event_id:, name: candidate[:name], party:, elected: false,
        group_letter: candidate[:group_letter], elected_at_count: candidate[:count], source_url: grp_and_candidates_url
      )
    end
  end

  def winners
    @winners ||= begin
      page = Councils::PageDownloader.call(candidates_elected_url)
      raise "Failed to download NSW LC candidates_elected page: #{candidates_elected_url}" if page.blank?

      results = NswStatePoliticians::Lc::CandidatesElectedPageParser.call(page)
      raise "No winners found on NSW LC candidates_elected page: #{candidates_elected_url}" if results.blank?

      results
    end
  end

  def group_party_names
    @group_party_names ||= begin
      page = Councils::PageDownloader.call(fp_by_grp_url)
      raise "Failed to download NSW LC fp_by_grp page: #{fp_by_grp_url}" if page.blank?

      NswStatePoliticians::Lc::FpByGrpParser.call(page)
    end
  end

  def candidates
    @candidates ||= begin
      page = Councils::PageDownloader.call(grp_and_candidates_url)
      raise "Failed to download NSW LC grp_and_candidates page: #{grp_and_candidates_url}" if page.blank?

      results = NswStatePoliticians::Lc::GrpAndCandidatesParser.call(page)
      raise "No candidates found on NSW LC grp_and_candidates page: #{grp_and_candidates_url}" if results.blank?

      results
    end
  end

  def candidates_elected_url
    "https://pastvtr.elections.nsw.gov.au/#{event_id}/LC/state/candidates_elected"
  end

  def fp_by_grp_url
    "https://pastvtr.elections.nsw.gov.au/#{event_id}/LC/state/fp_by_grp"
  end

  def grp_and_candidates_url
    "https://pastvtr.elections.nsw.gov.au/#{event_id}/LC/state/fp_grp_and_candidates"
  end
end
