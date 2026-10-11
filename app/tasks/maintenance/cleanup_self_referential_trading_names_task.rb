# Deletes TradingName rows whose name is identical to their owner's own name - they
# duplicate every search hit without adding any disambiguation value. Covers both
# Person and Group owners in one run. Fans each deletion out to a low-priority job
# rather than deleting synchronously. Run from /maintenance_tasks.
module Maintenance
  class CleanupSelfReferentialTradingNamesTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      TradingName.duplicating_owner_name
    end

    delegate :count, to: :collection

    def process(trading_name)
      if dry_run
        Rails.logger.info("[DRY RUN] Would delete TradingName ##{trading_name.id} (#{trading_name.name}) on #{trading_name.owner_type} ##{trading_name.owner_id}")
        return
      end

      Maintenance::DeleteSelfReferentialTradingNameJob.perform_async(trading_name.id)
    end
  end
end
