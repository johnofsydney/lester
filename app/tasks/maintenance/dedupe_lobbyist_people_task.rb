module Maintenance
  class DedupeLobbyistPeopleTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      Person.where(id: People::DeleteDuplicates.new.duplicate_ids(Person.only_in_lobbyists)).order(:id)
    end

    delegate :count, to: :collection

    # Re-derives the keeper at process-time, rather than trusting the ids
    # captured by `collection`, so that a resumed/re-run task stays safe to
    # process the same person twice (earlier merges may have already folded
    # this row's siblings together).
    def process(duplicate)
      return unless Person.exists?(duplicate.id)

      keeper = People::DeleteDuplicates.new.keeper_for(duplicate, scope: Person.only_in_lobbyists)
      return unless keeper

      if dry_run
        Rails.logger.info("[DRY RUN] Would merge Person ##{duplicate.id} (#{duplicate.name}) into ##{keeper.id}")
        return
      end

      keeper.merge!(duplicate)
    end
  end
end
