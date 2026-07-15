require 'sidekiq-scheduler'

class OpenAustralia::IngestPoliticiansJob
  include Sidekiq::Job

  def perform
    OpenAustralia::IngestPoliticians.call
  end
end
