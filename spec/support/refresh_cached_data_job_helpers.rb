module RefreshCachedDataJobHelpers
  def stub_refresh_cached_data_job(queue: nil)
    setter = double('Sidekiq::Job::Setter') # rubocop:disable RSpec/VerifiedDoubles
    stub = allow(Cache::RefreshCachedDataJob).to receive(:set)
    queue ? stub.with(queue: queue).and_return(setter) : stub.and_return(setter)
    allow(setter).to receive(:perform_async)
    setter
  end
end

RSpec.configure do |config|
  config.include RefreshCachedDataJobHelpers
end
