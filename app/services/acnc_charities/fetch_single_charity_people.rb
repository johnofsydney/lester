class ResponseFailed < StandardError; end
class NoResultsFound < StandardError; end

# frozen_string_literal: true
class AcncCharities::FetchSingleCharityPeople
  def self.call(charity)
    new(charity).call
  end

  def initialize(charity)
    @charity = charity
  end

  def call
    # First - set last_refreshed to today to avoid repeated retries in short time
    @charity.update!(last_refreshed: Time.current.to_date)

    # Part 1 - query API for UUID
    response = connection(search_url).get
    raise ResponseFailed.new("Request failed: #{response.inspect}") unless response.success? && response.body.present?

    body = JSON.parse(response.body)
    raise NoResultsFound.new("No results found: #{response.inspect}") if !body['results'].is_a?(Array) || body['results'][0].nil?

    @uuid = body['results'][0]['uuid']

    #  Part 2 - fetch people page
    response = connection(people_url).get
    raise ResponseFailed.new("People request failed: #{response.inspect}") unless response.success? && response.body.present?

    doc = Nokogiri::HTML(response.body)
    people_count = 0

    # Part 3 - parse people - they are held in .card-body elements
    cards = doc.css('.card-body')
    if cards.empty?
      Rails.logger.info("People not found for charity #{@charity.id} - will not retry")
      return {success: false, people_count: 0}
    end

    cards.each do |card|
      name = card.at_css('h4')&.text.to_s.strip
      title = card.at_css('li')&.text.to_s.strip.gsub('Role: ', '')

      next if name.blank? && title.blank?

      person = RecordPerson.call(name)
      membership = Membership.find_or_create_by(group: @charity, member: person)
      Position.find_or_create_by(membership:, title:)
      people_count += 1
    end

    Rails.logger.info "Successfully processed charity #{@charity.name} - #{people_count} people found"

    {success: true, people_count:}
  end

  private

  def search_url
    "https://www.acnc.gov.au/api/dynamics/search/charity?search=#{@charity.business_number}"
  end

  def people_url
    plain_people_url = "https://www.acnc.gov.au/charity/charities/#{@uuid}/people"
    encoded_url = URI.encode_www_form_component(plain_people_url)
    crawlbase_token = Rails.application.credentials.dig(:crawlbase, :javascript_token)
    page_wait = 5000

    "https://api.crawlbase.com/?token=#{crawlbase_token}&ajax_wait=true&page_wait=#{page_wait}&url=#{encoded_url}"
  end

  def connection(url)
    Faraday.new(url:) do |config|
      config.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'

      # Set timeout values (too big for normal use)
      config.options.timeout = 90        # 90 seconds for read timeout
      config.options.open_timeout = 30   # 30 seconds for connection timeout
    end
  end
end
