# The main entry point for ingesting contracts published or modified on a specific date
require 'sidekiq-scheduler'

class RefreshNodesCountJob
  include Sidekiq::Job

  # There are ~280k people and ~50k groups,
  # Running 2000 jobs per 5 mins would take ~80 mins to complete a full cycle

  QUANTITY = 2000
  STALE_THRESHOLD_TIMESTAMP = 8.days.ago

  def perform
    return unless entities_to_refresh?

    people_to_refresh.pluck(:id).each do |id|
      NodeCountJob.perform_async('Person', id)
    end

    groups_to_refresh.pluck(:id).each do |id|
      NodeCountJob.perform_async('Group', id)
    end

    # Re-enqueue itself until fully done
    self.class.perform_in(5.minutes)
  end

  def people_to_refresh
    @people_to_refresh ||= Person.nodes_count_expired.limit(QUANTITY)
  end

  def groups_to_refresh
    @groups_to_refresh ||= Group.nodes_count_expired.limit(QUANTITY)
  end

  def entities_to_refresh?
    people_to_refresh.any? || groups_to_refresh.any?
  end
end
