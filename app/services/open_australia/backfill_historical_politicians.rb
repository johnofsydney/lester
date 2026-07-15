class OpenAustralia::BackfillHistoricalPoliticians
  def self.call(from_id:, to_id:) = new(from_id:, to_id:).call

  def initialize(from_id:, to_id:)
    @from_id = from_id
    @to_id   = to_id
  end

  def call
    known_ids = ExternalIdentifier.where(source: 'open_australia', owner_type: 'Person',
                                         value: (from_id..to_id).map(&:to_s)).pluck(:value).to_set
    delay = 0.0

    (from_id..to_id).each do |person_id|
      next if known_ids.include?(person_id.to_s)

      OpenAustralia::ImportPoliticianRowJob.perform_in(delay, person_id.to_s, '1')
      OpenAustralia::ImportPoliticianRowJob.perform_in(delay, person_id.to_s, '2')
      delay += 0.3
    end
  end

  private

  attr_reader :from_id, :to_id
end
