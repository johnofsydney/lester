# maps the hash from the API into a nice Ruby object

class AusTender::Release
  def initialize(raw_release)
    @raw_release = raw_release
  end

  attr_reader :raw_release

  # def value
  #   contract['value']['amount']
  # end

  def release_id
    # NB This is unique for each release / amendment in the response.
    # BUT I wonder if it changes when the release is updated?
    # As the release does seem to reflect the latest Total amount etc, I suspect it does.
    # Therefore it's useless at identifying the amendment uniquely over time.
    raw_release['id']
  end

  def contract_id
    # The main parent contract ID - all amendments share this
    contract['id']
  end

  def award_id
    # parent and all amendments share the same award ID
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

  def amendment_id
    return nil if amendments.empty?

    amendments.first['id']
  end

  def item_id
    # THIS is the unique identifier for each release. There is one for the parent and a unique one for each amendment
    # The first part seems to relate to the contract scheme, the second is the unique UUID for the release
    contract['items'].first['id']
  end

  def uuid
    # allow us to fetch the item details page on the tenders website
    # https://www.tenders.gov.au/Cn/Show/59980167-303c-42ff-bd69-2e72f225c2c1

    uuid = item_id.split('-')[1]
    "#{uuid[0..7]}-#{uuid[8..11]}-#{uuid[12..15]}-#{uuid[16..19]}-#{uuid[20..31]}"
  end

  def scraped_page_data
    @scraped_page_data ||= AusTender::ScrapeSingleContractAmendment.new(uuid).perform
  end

  def amount
    (scraped_page_data[:amendment_value] || contract['value']['amount']).to_f
  end

  def effective_date
    Date.parse(scraped_page_data[:amendment_publish_date] || raw_release['date'])
  end

  def evidence
    "https://www.tenders.gov.au/Cn/Show/#{uuid}"
  end

  private

  def parties = raw_release['parties']
  def supplier = parties.find { |party| party['roles'].include?('supplier')}
  def purchaser = parties.find { |party| party['roles'].include?('procuringEntity')}
  def contract = raw_release['contracts'].first
  def amendments = contract['amendments'] || []
end