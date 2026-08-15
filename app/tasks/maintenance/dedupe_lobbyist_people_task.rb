module Maintenance
  class DedupeLobbyistPeopleTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      Person.where(id: People::DeleteDuplicates.new.duplicate_ids(Person.in_lobbyists))
    end

    delegate :count, to: :collection

    # Re-derives the keeper at process-time, rather than trusting the ids
    # captured by `collection`, so that a resumed/re-run task stays safe to
    # process the same person twice (earlier merges may have already folded
    # this row's siblings together).
    def process(duplicate)
      return unless Person.exists?(duplicate.id)

      keeper = People::DeleteDuplicates.new.keeper_for(duplicate, scope: Person.in_lobbyists) do |dup, candidate|
        compatible_employers?(dup, candidate)
      end

      unless keeper
        Rails.logger.info("Leaving Person ##{duplicate.id} (#{duplicate.name}) for manual review - no same-name lobbyist shares an employer")
        return
      end

      if dry_run
        Rails.logger.info("[DRY RUN] Would merge Person ##{duplicate.id} (#{duplicate.name}) into ##{keeper.id}")
        return
      end

      keeper.merge!(duplicate, queue: :low)
    end

    private

    # Two same-name lobbyists are safe to auto-merge if their non-Lobbyists-tag group
    # memberships overlap (a shared employer), or if either side has none recorded yet.
    # A duplicate whose only other memberships are disjoint from the candidate's is
    # presumed a different real person and left for manual review.
    def compatible_employers?(person, candidate)
      person_groups = other_group_ids(person)
      candidate_groups = other_group_ids(candidate)

      person_groups.empty? || candidate_groups.empty? || (person_groups & candidate_groups).any?
    end

    def other_group_ids(person)
      Membership.where(member: person).where.not(group_id: Group.lobbyists_tag.id).pluck(:group_id)
    end
  end
end
