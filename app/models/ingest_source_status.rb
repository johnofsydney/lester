class IngestSourceStatus < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # rubocop:disable Rails/SkipsModelValidations -- concurrent job workers upsert the same row; a
  # validate-then-update round trip would race, upsert is atomic.
  def self.record_success(key)
    now = Time.current
    upsert({ key: key, last_run_at: now, last_success_at: now, last_error: nil }, unique_by: :key)
  end

  def self.record_failure(key, error)
    now = Time.current
    upsert({ key: key, last_run_at: now, last_failure_at: now, last_error: error.message.to_s.truncate(1000) }, unique_by: :key)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def failing?
    last_failure_at.present? && last_failure_at == last_run_at
  end
end
