# Deletes Memberships whose polymorphic member reference (member_type/member_id) points at a
# Person or Group that no longer exists. Unlike the group_id side (which has a DB-level foreign
# key), the polymorphic member side has none, so a Person/Group destroyed without cascading its
# member-side Memberships (see Group#memberships_as_member) leaves rows like this behind. Left in
# place, they crash NodeMethods#best_group_memberships when a cache job later tries to look up the
# now-missing member. Run from /maintenance_tasks.
module Maintenance
  class CleanupOrphanedMembershipsTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      Membership.where(id: orphaned_ids)
    end

    delegate :count, to: :collection

    def process(membership)
      if dry_run
        Rails.logger.info("[DRY RUN] Would delete orphaned Membership ##{membership.id} (member_type: #{membership.member_type}, member_id: #{membership.member_id})")
        return
      end

      membership.destroy
    end

    private

    def orphaned_ids
      %w[Person Group].flat_map do |member_type|
        klass = member_type.constantize
        # reselect, not select: Person/Group's `lazy_columns` already applies a default select,
        # so a plain .select(:id) would append rather than replace it and break the subquery.
        Membership.where(member_type: member_type).where.not(member_id: klass.reselect(:id)).pluck(:id)
      end
    end
  end
end
