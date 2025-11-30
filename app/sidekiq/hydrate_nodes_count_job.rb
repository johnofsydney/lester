# The main entry point for ingesting contracts published or modified on a specific date
require 'sidekiq-scheduler'

class HydrateNodesCountJob
  include Sidekiq::Job

  QUANTITY = 500

  def perform
    people = Person.where(nodes_count_cached: nil).or(Person.where(nodes_count_cached_at: ..8.days.ago))
    groups = Group.where(nodes_count_cached: nil).or(Group.where(nodes_count_cached_at: ..8.days.ago))

    people.take(QUANTITY).pluck(:id).each do |id|
      NodeCountJob.perform_async('Person', id)
    end

    groups.take(QUANTITY).pluck(:id).each do |id|
      NodeCountJob.perform_async('Group', id)
    end
  end
end
