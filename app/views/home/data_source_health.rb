class Home::DataSourceHealth
  attr_reader :label, :url, :frequency, :keys

  def initialize(label:, frequency:, keys: [], url: nil)
    @label = label
    @url = url
    @frequency = frequency
    @keys = keys
  end

  def statuses
    @statuses ||= IngestSourceStatus.where(key: keys)
  end

  def state
    return :manual if keys.empty?
    return :unknown if statuses.none?

    statuses.any?(&:failing?) ? :failing : :ok
  end

  def last_run_at
    statuses.filter_map(&:last_run_at).max
  end
end
