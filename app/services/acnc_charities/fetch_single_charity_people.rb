require 'selenium-webdriver'

class AcncCharities::FetchSingleCharityPeople
  def self.perform(charity)
    new(charity).perform
  end

  def initialize(charity)
    @charity = charity
  end

  def perform
    # Part 1 - Go to the search page, search for the charity by ABN, get the UUID from the results
    conn = Faraday.new(url: search_url) do |config|
      config.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    end

    response = conn.get

    return { success: false, error: 'Request failed' } unless response.success?

    body = JSON.parse(response.body)
    @uuid = body['results'][0]['uuid']


    # Part 2 - Go to the people page for that charity UUID, scrape the people data using Selenium
    driver = setup_selenium_driver

    driver.get(people_url)

    # Wait for the Vue app to load
    wait = Selenium::WebDriver::Wait.new(timeout: 15)

    # Wait for people content to appear (adjust selector as needed)
    wait.until do
      driver.find_elements(css: '.charity-people').any?
    end

    # Give it a bit more time for all content to load
    sleep(1)

    cards = driver.find_elements(css: '.card-body')
    cards.each do |card|
      name = safe_text(card.find_elements(css: 'h4')[0])
      title = safe_text(card.find_elements(css: 'li')[0]).gsub('Role: ', '')

      person = RecordPerson.call(name)
      membership = Membership.find_or_create_by(group: @charity, member: person)
      position = Position.find_or_create_by(membership:, title:)

      Rails.logger.info("Recorded person: #{name} - #{title} to charity #{@charity.name}")
    end

    driver.quit
  end

  def search_url
    "https://www.acnc.gov.au/api/dynamics/search/charity?search=#{@charity.business_number}"
  end

  def people_url
    "https://www.acnc.gov.au/charity/charities/#{@uuid}/people"
  end

  def setup_selenium_driver
    options = Selenium::WebDriver::Chrome::Options.new

    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--remote-debugging-port=9222')
    options.add_argument('--disable-extensions')
    options.add_argument('--disable-web-security')
    options.add_argument('--window-size=1920,1080')

    # User agent to appear more like a real browser
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36')

    begin
      Selenium::WebDriver.for(:chrome, options:)
    rescue Selenium::WebDriver::Error::WebDriverError => e
      Rails.logger.error "Chrome driver setup failed: #{e.message}"
      raise StandardError, "Chrome browser not available. Install Google Chrome or use a different scraping method."
    end
  end

  def safe_text(element)
    element.text.strip
  rescue StandardError
    ''
  end

  def safe_element_text(parent_element, selector)
    element = parent_element.find_element(css: selector)
    element.text.strip
  rescue Selenium::WebDriver::Error::NoSuchElementError
    ''
  end
end