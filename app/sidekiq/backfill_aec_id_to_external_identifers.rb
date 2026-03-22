class BackfillAecIdToExternalIdentifers
  # Migrates existing aec_id columns on people and groups into the external_identifers table.
  # Run after deploying the CreateExternalIdentifers migration.
  #
  # Trigger from console with:
  #   BackfillAecIdToExternalIdentifers.perform_async
  include Sidekiq::Job

  BATCH_SIZE = 500

  def perform
    backfill(Person)
    backfill(Group)
  end

  private

  def backfill(klass)
    klass.where.not(aec_id: [nil, '']).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      batch.each do |record|
        ExternalIdentifer.find_or_create_by!(
          owner_type: klass.name,
          owner_id: record.id,
          source: 'aec',
          value: record.aec_id
        )
      rescue ActiveRecord::RecordNotUnique
        # already exists — safe to skip
      end
    end
  end
end
