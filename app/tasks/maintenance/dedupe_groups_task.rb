# Folds every same-name duplicate Group into its lowest-id keeper (see issue #342 -
# 221 names, 537 duplicate rows). A same-name Group pair can be incompatible to merge
# (clashing business number, or clashing external identifier source) - those are left
# in place for manual review rather than aborting the whole run. Run from
# /maintenance_tasks.
module Maintenance
  class DedupeGroupsTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      Group.where(id: Groups::DeleteDuplicates.new.duplicate_ids)
    end

    delegate :count, to: :collection

    # Re-derives the keeper at process-time, rather than trusting the id captured by
    # `collection`, so that a resumed/re-run task stays safe to process the same group
    # twice (earlier merges may have already folded this row's siblings together).
    def process(duplicate)
      return unless Group.exists?(duplicate.id)

      keeper = Groups::DeleteDuplicates.new.keeper_for(duplicate)
      return unless keeper

      if dry_run
        Rails.logger.info("[DRY RUN] Would merge Group ##{duplicate.id} (#{duplicate.name}) into ##{keeper.id}")
        return
      end

      keeper.merge!(duplicate)
    rescue RuntimeError => e
      Rails.logger.info("Leaving Group ##{duplicate.id} (#{duplicate.name}) for manual review - #{e.message}")
    end
  end
end
