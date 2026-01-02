class ResponseFailed < StandardError; end
class TooManyRequests < StandardError; end
class ObjectMoved < StandardError; end

# frozen_string_literal: true
class AusTender::ScrapeSingleContractAmendment
  attr_reader :data

  def self.perform(uuid)
    new(uuid).perform
  end

  def initialize(uuid)
    @uuid = uuid
  end

  def perform
    response = connection(url).get

    if response.status == 429
      Circuit::AusTenderScraperSwitch.use_crawlbase_scraping
      Rails.logger.info "Switched to Crawlbase scraping after receiving 429 Too Many Requests for Amendment #{@uuid}. use_crawlbase_scraping=#{Current.use_crawlbase_for_aus_tender_scraping}"

      raise TooManyRequests.new("429: Too Many Requests: #{response.inspect}")
    end

    raise ObjectMoved.new("Object Moved: #{response.inspect}") if response.status == 302
    raise ResponseFailed.new("Request failed: #{response.inspect}") unless response.success? && response.body.present?

    doc = Nokogiri::HTML(response.body)
    list = doc.css('.listInner')[0]
    @data = list.css('.list-desc')
                .map {|node| element_mapper(node) }
                .inject(:merge)

    {
      uuid: @uuid,
      amendment_cn_id: data['CN ID'],
      amendment_publish_date: data['Amendment Publish Date'],
      amendment_execution_date: data['Execution Date'],
      amendment_start_date: data['Amendment Start Date'],
      amendment_value:
    }
  end

  def original_url
    "https://www.tenders.gov.au/Cn/Show/#{@uuid}"
  end

  def url
    if SidekiqUtils.get_redis_key('aus_tender_use_crawlbase') == 'true'
      crawlbase_url
    else
      original_url
    end
  end

  def crawlbase_url
    encoded_url = URI.encode_www_form_component(original_url)
    crawlbase_token = Rails.application.credentials.dig(:crawlbase, :normal_token)

    "https://api.crawlbase.com/?token=#{crawlbase_token}&url=#{encoded_url}"
  end

  def amendment_value
    return nil if data['Amendment Value (AUD)'].nil?

    data['Amendment Value (AUD)'].delete('$,').to_f
  end

  def connection(url)
    Faraday.new(url:) do |config|
      config.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
      config.headers['FYI'] = 'I am only after the "Amendment Value (AUD)" and "Amendment Publish Date" which do not appear to be in the API response (eg https://api.tenders.gov.au/ocds/findById/CN3779137). If this changes, please let me know - mr.john.coote@gmail.com'

    # Set timeout values (too big for normal use)
    config.options.timeout = 90        # 90 seconds for read timeout
    config.options.open_timeout = 30   # 30 seconds for connection timeout
    end
  end

  def element_mapper(list_node)
    label = list_node.css('span')&.text
    return {} if label.nil?

    label = label.strip.chomp(':')

    value = list_node.css('.list-desc-inner')[0]&.text
    return {} if value.nil?

    value = value.strip

    { label => value }
  end
end
