# Deletes TradingName rows whose (already-normalised) name matches their owner's own
# (already-normalised) name - the years-of-history backlog left behind before
# `Record::SavingHelpers#add_to_trading_names` started skipping this case (see issue
# #315). Covers both Person and Group owners in one run. Run from /maintenance_tasks.
module Maintenance
  class CleanupSelfReferentialTradingNamesTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      TradingName.where(
        "trading_names.owner_type = 'Person' AND EXISTS (SELECT 1 FROM people WHERE people.id = trading_names.owner_id AND people.name = trading_names.name)
         OR trading_names.owner_type = 'Group' AND EXISTS (SELECT 1 FROM groups WHERE groups.id = trading_names.owner_id AND groups.name = trading_names.name)"
      )
    end

    delegate :count, to: :collection

    def process(trading_name)
      if dry_run
        Rails.logger.info("[DRY RUN] Would delete TradingName ##{trading_name.id} (#{trading_name.name}) on #{trading_name.owner_type} ##{trading_name.owner_id}")
        return
      end

      trading_name.destroy!
    end
  end
end
