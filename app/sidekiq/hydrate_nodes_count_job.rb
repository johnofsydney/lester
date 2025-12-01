# The main entry point for ingesting contracts published or modified on a specific date
require 'sidekiq-scheduler'

class HydrateNodesCountJob
  include Sidekiq::Job

  # as of 1/12/2025 there are 231,876 people and 84,548 groups
  # Running this job at a frequency of 4 times per hour means we can process
  # approximately 2,000 people and 2,000 groups every 15 minutes
  # which means we can re-hydrate the entire dataset in just over 38 hours

  # jobs to spread out in time using id as the randomizer

  QUANTITY = 2000

  def perform
    people = Person.where(nodes_count_cached: nil).or(Person.where(nodes_count_cached_at: ..8.days.ago))
    groups = Group.where(nodes_count_cached: nil).or(Group.where(nodes_count_cached_at: ..8.days.ago))

    if people.any?
      people.take(QUANTITY).pluck(:id).each do |id|
        delay = id % 10
        NodeCountJob.perform_in(delay.seconds, 'Person', id)
      end
    end

    if groups.any?
      groups.take(QUANTITY).pluck(:id).each do |id|
        delay = id % 10
        NodeCountJob.perform_in(delay.seconds, 'Group', id)
      end
    end
  end
end
