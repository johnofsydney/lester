class BackfillAecIdToExternalIdentifiers
  # Migrates existing aec_id columns on people and groups into the external_identifiers table.
  # Run after deploying the CreateExternalIdentifiers migration.
  #
  # Trigger from console with:
  #   BackfillAecIdToExternalIdentifiers.perform_async
  include Sidekiq::Job

  BATCH_SIZE = 500

  def perform
    backfill(Person)
    backfill(Group)
  end

  private

  def backfill(klass)
    klass.where.not(aec_id_legacy: [nil, '']).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      batch.each do |record|
        ExternalIdentifier.find_or_create_by!(
          owner_type: klass.name,
          owner_id: record.id,
          source: 'aec',
          value: record.aec_id_legacy
        )
      rescue ActiveRecord::RecordNotUnique
        # already exists — safe to skip
      end
    end
  end
end
