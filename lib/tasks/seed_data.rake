# Produces and loads a small, curated subset of production data for local/staging use.
#
# Workflow:
#   1. Load a full production data dump into your *local* development database (see
#      docs/runbooks/creating-prod-dump-as-staging.md for how to get a dump), then run:
#        bin/rails seed_data:extract
#      This writes YAML fixtures to db/seed_data/*.yml.
#   2. Commit those files.
#   3. Anywhere else (a fresh local dev DB, staging), run:
#        bin/rails db:seed
#      which loads db/seed_data/*.yml, preserving primary keys (several tag/group IDs
#      are hardcoded — see Group.charities_tag etc. — so IDs must survive the round trip).
#
# extract is intentionally local-only: it must never run against a deployed environment
# (staging or production), even by accident. seed is intentionally development/staging-only
# (see db/seeds.rb) and is only ever invoked via `db:seed` — never exposed in the UI.
namespace :seed_data do
  desc 'Extract a small curated subset of the current database into db/seed_data/*.yml'
  task extract: :environment do
    unless Rails.env.development?
      abort "Refusing to extract from RAILS_ENV=#{Rails.env} — this task must only run " \
            'against a local development database (temporarily loaded with a full data ' \
            'copy), never against a deployed environment.'
    end

    top_groups_limit = 30
    top_people_limit = 50
    federal_members_limit = 250
    transfers_limit = 2000

    # Groups whose IDs are hardcoded elsewhere in the codebase (Group.charities_tag and
    # friends) plus every Tag (party labels, category labels like Charities/Lobbyists) and
    # the major party tags (redundant with all_tag_ids, but kept explicit for clarity).
    core_group_ids = [124_513, 124_509, 124_510, 124_514, 877, 132_067]
    all_tag_ids = Tag.pluck(:id)
    major_party_group_ids = Group.where(name: Group.all_named_parties).pluck(:id)

    top_group_ids = Group.joins(
      'LEFT JOIN transfers t ON (t.giver_type = \'Group\' AND t.giver_id = groups.id) ' \
      'OR (t.taker_type = \'Group\' AND t.taker_id = groups.id)'
    ).group('groups.id').order(Arel.sql('COUNT(t.id) DESC')).limit(top_groups_limit).pluck(:id)

    selected_group_ids = (core_group_ids + all_tag_ids + major_party_group_ids + top_group_ids).uniq

    federal_member_ids = Membership.where(group_id: 877, member_type: 'Person')
                                   .order(start_date: :desc)
                                   .limit(federal_members_limit)
                                   .pluck(:member_id)

    top_person_ids = Person.joins(
      'LEFT JOIN transfers t ON (t.giver_type = \'Person\' AND t.giver_id = people.id) ' \
      'OR (t.taker_type = \'Person\' AND t.taker_id = people.id)'
    ).group('people.id').order(Arel.sql('COUNT(t.id) DESC')).limit(top_people_limit).pluck(:id)

    selected_person_ids = (federal_member_ids + top_person_ids).uniq

    # Pull in every group a selected person/group is (or was) a member of — e.g. a
    # federal MP's party, a company's lobbyist-register tag — without following tag
    # groups back out to their full membership (that's how a 6-row tag set stays small
    # instead of pulling in every charity/lobbyist in the country).
    known_member_scope = Membership.where(member_type: 'Person', member_id: selected_person_ids)
                                   .or(Membership.where(member_type: 'Group', member_id: selected_group_ids))
    selected_group_ids = (selected_group_ids + known_member_scope.pluck(:group_id)).uniq

    memberships = Membership.where(group_id: selected_group_ids)
                            .where(member_type: 'Person', member_id: selected_person_ids)
                            .or(
                              Membership.where(group_id: selected_group_ids)
                                        .where(member_type: 'Group', member_id: selected_group_ids)
                            )

    positions = Position.where(membership_id: memberships.select(:id))

    # A transfer is in scope when both ends are entities we've already selected.
    person_or_group = lambda do |type_col, id_col|
      "((#{type_col} = 'Person' AND #{id_col} IN (#{selected_person_ids.join(',').presence || 'NULL'})) " \
        "OR (#{type_col} = 'Group' AND #{id_col} IN (#{selected_group_ids.join(',').presence || 'NULL'})))"
    end
    transfers = Transfer.where(person_or_group.call('giver_type', 'giver_id'))
                        .where(person_or_group.call('taker_type', 'taker_id'))
                        .order(amount: :desc)
                        .limit(transfers_limit)

    external_identifiers = ExternalIdentifier.where(owner_type: 'Person', owner_id: selected_person_ids)
                                             .or(ExternalIdentifier.where(owner_type: 'Group', owner_id: selected_group_ids))

    trading_names = TradingName.where(owner_type: 'Person', owner_id: selected_person_ids)
                               .or(TradingName.where(owner_type: 'Group', owner_id: selected_group_ids))

    seed_data_dir = Rails.root.join('db/seed_data')
    FileUtils.mkdir_p(seed_data_dir)

    dump(seed_data_dir, 'groups', Group.where(id: selected_group_ids))
    dump(seed_data_dir, 'people', Person.where(id: selected_person_ids))
    dump(seed_data_dir, 'memberships', memberships)
    dump(seed_data_dir, 'positions', positions)
    dump(seed_data_dir, 'transfers', transfers)
    dump(seed_data_dir, 'external_identifiers', external_identifiers)
    dump(seed_data_dir, 'trading_names', trading_names)

    puts "Extracted #{selected_group_ids.size} groups (incl. #{all_tag_ids.size} tags), " \
         "#{selected_person_ids.size} people, " \
         "#{memberships.count} memberships, #{positions.count} positions, " \
         "#{transfers.count} transfers into #{seed_data_dir}"
  end

  def dump(dir, name, relation)
    rows = relation.reorder(nil).map(&:attributes)
    File.write(dir.join("#{name}.yml"), YAML.dump(rows))
  end
end
