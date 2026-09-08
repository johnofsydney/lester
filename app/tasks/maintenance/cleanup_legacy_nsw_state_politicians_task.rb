# Deletes every Membership (and its Positions) in Group.nsw_parliament -- the legacy, one-time
# copy/paste import of NSW state politicians described in issue #248, unreliable and not
# repeatable. Must run before docs/plans/0011-ingest-nsw-state-politicians-design.md's real
# pastvtr-sourced ingest lands data, so the new work can assume a clean slate for this Group.
#
# Unlike the equivalent federal politicians cleanup (rake lester:cleanup_legacy_politician_memberships,
# which only ever deletes Memberships/Positions, never People), this also deletes any Person left
# with zero Memberships once their NSW Parliament one is gone -- this legacy import was a
# standalone copy/paste job, so a state MP with no other data source touching them (no donations,
# no other Group Membership) is very plausibly a person that exists in this DB only because of this
# one bad import. See docs/runbooks/nsw-state-politicians-legacy-cleanup.md for the full reasoning.
#
# The orphan check happens per-Membership, immediately after that Membership is deleted (not as a
# separate pass over the whole Group afterwards) -- this is what makes the task safely resumable:
# job-iteration may process this collection across multiple batches/jobs, and checking "does this
# specific Person have zero Memberships left, right now" is correct regardless of what order or how
# many separate runs the rest of the collection gets processed in. Run from /maintenance_tasks.
module Maintenance
  class CleanupLegacyNswStatePoliticiansTask < MaintenanceTasks::Task
    attribute :dry_run, :boolean, default: true

    def collection
      Membership.where(group: Group.nsw_parliament)
    end

    delegate :count, to: :collection

    def process(membership)
      person = membership.member if membership.member_type == 'Person'

      if dry_run
        Rails.logger.info("[DRY RUN] Would delete Membership ##{membership.id} (#{membership.member_type} ##{membership.member_id}) and its Positions")
        Rails.logger.info("[DRY RUN] Would also delete Person ##{person.id} (#{person.name}) -- would become orphaned") if person && orphaned_excluding?(person, membership)
        return
      end

      membership.destroy # cascades to its Positions (Membership has_many :positions, dependent: :destroy)

      person.destroy if person && orphaned?(person)
    end

    private

    def orphaned_excluding?(person, membership)
      Membership.where(member: person).where.not(id: membership.id).none?
    end

    def orphaned?(person)
      Membership.where(member: person).none?
    end
  end
end
