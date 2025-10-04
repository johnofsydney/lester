# maps the hash from the API into a nice Ruby object

class AusTender::Release
  def initialize(raw_release)
    @ocid = raw_release['ocid']
    @date = raw_release['date']
    @external_id = raw_release['id']

    @raw_release = raw_release
  end

  attr_reader :ocid, :date, :external_id, :raw_release

  def value
    contract['value']['amount']
  end

  def contract_id
    contract['id']
  end

  def award_id
    raw_release['awards'].first['id']
  end

  def tag
    raw_release['tag'].first
  end

  def supplier_name
    supplier['name']
  end

  def supplier_abn
    supplier.dig('additionalIdentifiers', 0, 'id')
  end

  def purchaser_name
    purchaser['name']
  end

  def purchaser_abn
    purchaser.dig('additionalIdentifiers', 0, 'id')
  end

  def description
    contract['description']
  end

  def amends_release_id
    amendments = raw_release['contracts'].first['amendments']

    amendments.present? ? amendments.first['amendsReleaseID'] : nil
  end

  def amendment_index
    amendments = raw_release['contracts'].first['amendments']
    amendment_id = amendments.present? ? amendments.first['id'] : "#{contract_id}-0"

    amendment_id.match(/\d+$/)[0].to_i
  end

  attr_accessor :previous_value

  def augment(previous_value: 0.0)
    self.previous_value = previous_value

    self
  end

  private

  def parties = raw_release['parties']
  def supplier = parties.find { |party| party['roles'].include?('supplier')}
  def purchaser = parties.find { |party| party['roles'].include?('procuringEntity')}
  def contract = raw_release['contracts'].first
end