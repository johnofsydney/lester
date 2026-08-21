# Loads the curated data subset from db/seed_data/*.yml, produced by `bin/rails seed_data:extract`
# (see lib/tasks/seed_data.rake). Preserves primary keys, since several group IDs are
# hardcoded elsewhere in the codebase (Group.charities_tag and friends).
#
# Safe to run against an empty database only — it does not clear existing data first.

unless %w[development staging].include?(Rails.env)
  puts "Skipping db:seed for RAILS_ENV=#{Rails.env} (only development/staging load seed data; " \
       'the test DB should start empty, and production must never load it).'
  return
end

SEED_DATA_DIR = Rails.root.join('db/seed_data')

# Order matters: memberships/positions/transfers/external_identifiers/trading_names
# reference people/groups.
SEED_TABLES = %w[
  groups
  people
  memberships
  positions
  transfers
  external_identifiers
  trading_names
].freeze

SEED_TABLES.each do |table|
  path = SEED_DATA_DIR.join("#{table}.yml")
  unless File.exist?(path)
    puts "Skipping #{table}: #{path} not found (run `bin/rails seed_data:extract` on a full-data DB first)"
    next
  end

  rows = YAML.unsafe_load_file(path)
  if rows.empty?
    puts "Skipping #{table}: no rows"
    next
  end

  model = table.classify.constantize
  model.insert_all(rows)
  ActiveRecord::Base.connection.reset_pk_sequence!(table)
  puts "Loaded #{rows.size} rows into #{table}"
end
